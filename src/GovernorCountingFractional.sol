// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/compatibility/GovernorCompatibilityBravo.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

/**
 * @notice Extension of {Governor} for 3 option fractional vote counting. When
 * voting, a delegate may split their vote weight between Against/For/Abstain.
 * This is most useful when the delegate is itself a contract, implementing its
 * own rules for voting. By allowing a contract-delegate to split its vote
 * weight, the voting preferences of many disparate token holders can be rolled
 * up into a single vote to the Governor itself. Some example use cases include
 * voting with tokens that are held by a DeFi pool, voting from L2 with tokens
 * held by a bridge, or voting privately from a shielded pool using zero
 * knowledge proofs.
 */
contract GovernorCountingFractional is Governor, GovernorSettings, GovernorVotes, GovernorVotesQuorumFraction, GovernorTimelockControl{

    struct ProposalVote {
        uint128 againstVotes;
        uint128 forVotes;
        uint128 abstainVotes;
    }

    /**
     * @dev Mapping from proposal ID to vote tallies for that proposal.
     */
    mapping(uint256 => ProposalVote) private _proposalVotes;

    /**
     * @dev Mapping from proposal ID and address to the weight the address
     * has cast on that proposal, e.g. _proposalVotersWeightCast[42][0xBEEF]
     * would tell you the number of votes that 0xBEEF has cast on proposal 42.
     */
    mapping(uint256 => mapping(address => uint128)) private _proposalVotersWeightCast;

    /**
     * @dev Mapping from voter address to signature-based vote nonce. The
     * voter's nonce increments each time a signature-based vote is cast with
     * fractional voting params and must be included in the `params` as the last
     * 16 bytes when signing for a fractional vote.
     */
    mapping(address => uint128) public fractionalVoteNonce;

    constructor(string memory _name, IVotes _token, TimelockController _timelock, uint256 _votingdelay, uint256 _votingperiod, uint256 _proposalthreshold, uint256 _quorumfraction)
        Governor(_name)
        GovernorSettings(_votingdelay, _votingperiod, _proposalthreshold)
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(_quorumfraction)
        GovernorTimelockControl(_timelock)
    {}

    /**
     * @dev See {IGovernor-COUNTING_MODE}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function COUNTING_MODE() public pure virtual override returns (string memory) {
        return "support=bravo&quorum=for,abstain&params=fractional";
    }

    /**
     * @dev See {IGovernor-hasVoted}.
     */
    function hasVoted(uint256 proposalId, address account) public view virtual override returns (bool) {
        return _proposalVotersWeightCast[proposalId][account] > 0;
    }

    /**
     * @dev Get the number of votes cast thus far on proposal `proposalId` by
     * account `account`. Useful for integrations that allow delegates to cast
     * rolling, partial votes.
     */
    function voteWeightCast(uint256 proposalId, address account) public view returns (uint128) {
      return _proposalVotersWeightCast[proposalId][account];
    }

    /**
     * @dev Accessor to the internal vote counts.
     */
    function proposalVotes(uint256 proposalId)
        public
        view
        virtual
        returns (
            uint256 againstVotes,
            uint256 forVotes,
            uint256 abstainVotes
        )
    {
        ProposalVote storage proposalVote = _proposalVotes[proposalId];
        return (proposalVote.againstVotes, proposalVote.forVotes, proposalVote.abstainVotes);
    }

    /**
     * @dev See {Governor-_quorumReached}.
     */
    function _quorumReached(uint256 proposalId) internal view virtual override returns (bool) {
        ProposalVote storage proposalVote = _proposalVotes[proposalId];

        return quorum(proposalSnapshot(proposalId)) <= proposalVote.forVotes + proposalVote.abstainVotes;
    }

    /**
     * @dev See {Governor-_voteSucceeded}. In this module, forVotes must be > againstVotes.
     */
    function _voteSucceeded(uint256 proposalId) internal view virtual override returns (bool) {
        ProposalVote storage proposalVote = _proposalVotes[proposalId];

        return proposalVote.forVotes > proposalVote.againstVotes;
    }

    /**
     * @notice See {Governor-_countVote}.
     *
     * @dev Function that records the delegate's votes.
     *
     * If the `voteData` bytes parameter is empty, then this module behaves
     * identically to GovernorBravo. That is, it assigns the full weight of the
     * delegate to the `support` parameter, which follows the `VoteType` enum
     * from Governor Bravo.
     *
     * If the `voteData` bytes parameter is not zero, then it _must_ be three
     * packed uint128s, totaling 48 bytes, representing the weight the delegate
     * assigns to Against, For, and Abstain respectively, i.e.
     * `abi.encodePacked(againstVotes, forVotes, abstainVotes)`. The sum total of
     * the three decoded vote weights _must_ be less than or equal to the
     * delegate's remaining weight on the proposal, i.e. their checkpointed
     * total weight minus votes already cast on the proposal.
     *
     * See `_countVoteNominal` and `_countVoteFractional` for more details.
     */
    function _countVote(
        uint256 proposalId,
        address account,
        uint8 support,
        uint256 totalWeight,
        bytes memory voteData
    ) internal virtual override {
        require(totalWeight > 0, "GovernorCountingFractional: no weight");
        if (_proposalVotersWeightCast[proposalId][account] >= totalWeight) {
          revert("GovernorCountingFractional: all weight cast");
        }

        uint128 safeTotalWeight = SafeCast.toUint128(totalWeight);

        if (voteData.length == 0) {
            _countVoteNominal(proposalId, account, safeTotalWeight, support);
        } else {
            _countVoteFractional(proposalId, account, safeTotalWeight, voteData);
        }
    }

    /**
     * @dev Record votes with full weight cast for `support`.
     *
     * Because this function votes with the delegate's full weight, it can only
     * be called once per proposal. It will revert if combined with a fractional
     * vote before or after.
     */
    function _countVoteNominal(
        uint256 proposalId,
        address account,
        uint128 totalWeight,
        uint8 support
    ) internal {
        require(
            _proposalVotersWeightCast[proposalId][account] == 0,
            "GovernorCountingFractional: vote would exceed weight"
        );

        _proposalVotersWeightCast[proposalId][account] = totalWeight;

        if (support == uint8(GovernorCompatibilityBravo.VoteType.Against)) {
            _proposalVotes[proposalId].againstVotes += totalWeight;
        } else if (support == uint8(GovernorCompatibilityBravo.VoteType.For)) {
            _proposalVotes[proposalId].forVotes += totalWeight;
        } else if (support == uint8(GovernorCompatibilityBravo.VoteType.Abstain)) {
            _proposalVotes[proposalId].abstainVotes += totalWeight;
        } else {
            revert("GovernorCountingFractional: invalid support value, must be included in VoteType enum");
        }
    }

    /**
     * @dev Count votes with fractional weight.
     *
     * `voteData` is expected to be three packed uint128s, i.e.
     * `abi.encodePacked(againstVotes, forVotes, abstainVotes)`.
     *
     * This function can be called multiple times for the same account and
     * proposal, i.e. partial/rolling votes are allowed. For example, an account
     * with total weight of 10 could call this function three times with the
     * following vote data:
     *   - against: 1, for: 0, abstain: 2
     *   - against: 3, for: 1, abstain: 0
     *   - against: 1, for: 1, abstain: 1
     * The result of these three calls would be that the account casts 5 votes
     * AGAINST, 2 votes FOR, and 3 votes ABSTAIN on the proposal. Though
     * partial, votes are still final once cast and cannot be changed or
     * overridden. Subsequent partial votes simply increment existing totals.
     *
     * Note that if partial votes are cast, all remaining weight must be cast
     * with _countVoteFractional: _countVoteNominal will revert.
     */
    function _countVoteFractional(
        uint256 proposalId,
        address account,
        uint128 totalWeight,
        bytes memory voteData
    ) internal {
        require(voteData.length == 48, "GovernorCountingFractional: invalid voteData");

        (uint128 _againstVotes, uint128 _forVotes, uint128 _abstainVotes) = _decodePackedVotes(voteData);

        uint128 _existingWeight = _proposalVotersWeightCast[proposalId][account];
        uint256 _newWeight = uint256(_againstVotes) + _forVotes + _abstainVotes + _existingWeight;

        require(_newWeight <= totalWeight, "GovernorCountingFractional: vote would exceed weight");

        // It's safe to downcast here because we've just confirmed that
        // _newWeight <= totalWeight, and totalWeight is a uint128.
        _proposalVotersWeightCast[proposalId][account] = uint128(_newWeight);

        ProposalVote memory _proposalVote = _proposalVotes[proposalId];
        _proposalVote = ProposalVote(
            _proposalVote.againstVotes + _againstVotes,
            _proposalVote.forVotes + _forVotes,
            _proposalVote.abstainVotes + _abstainVotes
        );

        _proposalVotes[proposalId] = _proposalVote;
    }

    uint256 constant internal _MASK_HALF_WORD_RIGHT = 0xffffffffffffffffffffffffffffffff; // 128 bits of 0's, 128 bits of 1's

    /**
     * @dev Decodes three packed uint128's. Uses assembly because of a Solidity
     * language limitation which prevents slicing bytes stored in memory, rather
     * than calldata.
     */
    function _decodePackedVotes(bytes memory voteData)
        internal
        pure
        returns (
            uint128 againstVotes,
            uint128 forVotes,
            uint128 abstainVotes
        )
    {
        assembly {
            againstVotes := shr(128, mload(add(voteData, 0x20)))
            forVotes := and(_MASK_HALF_WORD_RIGHT, mload(add(voteData, 0x20)))
            abstainVotes := shr(128, mload(add(voteData, 0x40)))
        }
    }

    /**
     * @notice Cast a vote with a reason and additional encoded parameters using
     * the user's cryptographic signature.
     *
     * Emits a {VoteCast} or {VoteCastWithParams} event depending on the length
     * of params.
     *
     * @dev If casting a fractional vote via `params`, the voter's current nonce
     * must be appended to the `params` as the last 16 bytes and included in the
     * signature. I.e., the params used when constructing the signature would be:
     *
     *   abi.encodePacked(againstVotes, forVotes, abstainVotes, nonce)
     *
     * See {fractionalVoteNonce} and {_castVote} for more information.
     */
    function castVoteWithReasonAndParamsBySig(
        uint256 proposalId,
        uint8 support,
        string calldata reason,
        bytes memory params,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override(Governor, IGovernor) returns (uint256) {
        // Signature-based fractional voting requires `params` be two full words
        // in length:
        //   16 bytes for againstVotes.
        //   16 bytes for forVotes.
        //   16 bytes for abstainVotes.
        //   16 bytes for the signature nonce.
        // Signature-based nominal voting requires `params` be 0 bytes.
        require(
          params.length == 64 || params.length == 0,
          "GovernorCountingFractional: invalid params for signature-based vote"
        );

        address voter = ECDSA.recover(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        EXTENDED_BALLOT_TYPEHASH,
                        proposalId,
                        support,
                        keccak256(bytes(reason)),
                        keccak256(params)
                    )
                )
            ),
            v,
            r,
            s
        );

        // If params are zero-length all of the voter's weight will be cast so
        // we don't have to worry about checking/incrementing a nonce.
        if (params.length == 64) {
          // Get the nonce out of the params. It is the last half-word.
          uint128 nonce;
          assembly {
            nonce := and(
              // Perform bitwise AND operation on the data in the second word of
              // `params` with a mask of 128 zeros followed by 128 ones, i.e. take
              // the last 128 bits of `params`.
              _MASK_HALF_WORD_RIGHT,
              // Load the data from memory at the returned address.
              mload(
                // Skip the first 64 bytes (0x40):
                //   32 bytes encoding the length of the bytes array.
                //   32 bytes for the first word in the params
                // Return the memory address for the last word in params.
                add(params, 0x40)
              )
            )
          }

          require(
            fractionalVoteNonce[voter] == nonce,
            "GovernorCountingFractional: signature has already been used"
          );

          fractionalVoteNonce[voter]++;

          // Trim params in place to keep only the first 48 bytes (which are
          // the voting params) and save gas.
          assembly {
            mstore(params, 0x30)
          }
        }

        return _castVote(proposalId, voter, support, reason, params);
    }

    // The following functions are overrides required by Solidity.

    function votingDelay()
        public
        view
        override(IGovernor, GovernorSettings)
        returns (uint256)
    {
        return super.votingDelay();
    }

    function votingPeriod()
        public
        view
        override(IGovernor, GovernorSettings)
        returns (uint256)
    {
        return super.votingPeriod();
    }

    function quorum(uint256 blockNumber)
        public
        view
        override(IGovernor, GovernorVotesQuorumFraction)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    function state(uint256 proposalId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    function propose(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, string memory description)
        public
        override(Governor, IGovernor)
        returns (uint256)
    {
        return super.propose(targets, values, calldatas, description);
    }

    function proposalThreshold()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.proposalThreshold();
    }

    function _execute(uint256 proposalId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash)
        internal
        override(Governor, GovernorTimelockControl)
    {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _cancel(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash)
        internal
        override(Governor, GovernorTimelockControl)
        returns (uint256)
    {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor()
        internal
        view
        override(Governor, GovernorTimelockControl)
        returns (address)
    {
        return super._executor();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function cancel(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash)
        public
        override(Governor, IGovernor)
        returns (uint256)
    {
        return super.cancel(targets, values, calldatas, descriptionHash);
    }
}
