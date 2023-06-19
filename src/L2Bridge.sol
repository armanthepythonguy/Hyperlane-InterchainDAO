// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

interface IL2Governor{
    function proposalVotes(uint256 proposalId)
        external
        view
        returns (
            uint256 againstVotes,
            uint256 forVotes,
            uint256 abstainVotes
        );

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) external returns (uint256);

    function proposalDeadline(uint256 proposalId) external returns (uint256) ;
}

interface IMailBox{
    function dispatch(
        uint32 _destination,
        bytes32 _recipient,
        bytes calldata _body
    ) external returns (bytes32);
}

interface IInterchainGasPaymaster {
    event GasPayment(
        bytes32 indexed messageId,
        uint256 gasAmount,
        uint256 payment
    );

    function payForGas(
        bytes32 _messageId,
        uint32 _destinationDomain,
        uint256 _gasAmount,
        address _refundAddress
    ) external payable;

    function quoteGasPayment(uint32 _destinationDomain, uint256 _gasAmount)
        external
        view
        returns (uint256);
}

contract L2Bridge is Ownable{
    address public L2Governor;
    address public L1VoteDelegator;
    uint32 public L1Domain;
    address public mailBox;
    address public interchainGasPaymaster;
    modifier onlyMailbox{
        require(msg.sender == mailBox, "Only mailbox can send data !!!!");
        _;
    }
    constructor(address _mailBox, address _interchainGasPaymaster, uint32 _L1Domain){
        L1Domain = _L1Domain;
        mailBox = _mailBox;
        interchainGasPaymaster = _interchainGasPaymaster;
    }
    function init(address _L2Governor, address _L1VoteDelegator) external onlyOwner{
        L2Governor = _L2Governor;
        L1VoteDelegator = _L1VoteDelegator;
    }
    function bridgeVotes(uint256 _proposalId) external{
        uint256 proposalDeadlineBlock = IL2Governor(L2Governor).proposalDeadline(_proposalId);
        require(block.number >= proposalDeadlineBlock, "Wait till the proposal deadline is over to export the votes !!");
        (uint256 aganistVotes, uint256 forVotes, uint256 abstainVotes) = IL2Governor(L2Governor).proposalVotes(_proposalId);
        bytes32 messageId = IMailBox(mailBox).dispatch(
            L1Domain,
            addressToBytes32(L1VoteDelegator),
            abi.encode(_proposalId, abi.encodePacked(uint128(aganistVotes), uint128(forVotes), uint128(abstainVotes)))
        );
        uint256 quote = IInterchainGasPaymaster(interchainGasPaymaster).quoteGasPayment(L1Domain, 200000);
        IInterchainGasPaymaster(interchainGasPaymaster).payForGas{value: quote}(
            messageId,
            L1Domain,
            200000,
            address(this)
        );
    }
    function handle(uint32 _origin, bytes32 _sender, bytes memory _body) external onlyMailbox() {
        require(_origin == L1Domain, "Only messages from L1Domain is accepted !!");
        address sender = bytes32ToAddress(_sender);
        require(sender == L1VoteDelegator, "Only the vote delegator can send proposals !!!");
        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, string memory description) = abi.decode(_body, (address[], uint256[], bytes[], string));
        IL2Governor(L2Governor).propose(targets, values, calldatas, description);
    }
    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }
    function bytes32ToAddress(bytes32 _buf) internal pure returns (address) {
        return address(uint160(uint256(_buf)));
    }
    receive() payable external{}
}