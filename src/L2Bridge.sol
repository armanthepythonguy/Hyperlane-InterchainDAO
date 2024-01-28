// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@hyperlane-xyz/core/contracts/interfaces/IInterchainGasPaymaster.sol";
import "@hyperlane-xyz/core/contracts/interfaces/IMailbox.sol";
import "./interfaces/IL2Governor.sol";


contract L2Bridge is Ownable{
    address public L2Governor;
    address public L1VoteDelegator;
    uint32 public L1Domain;
    address public mailBox;
    modifier onlyMailbox{
        require(msg.sender == mailBox, "Only mailbox can send data !!!!");
        _;
    }
    constructor(address _mailBox, uint32 _L1Domain){
        L1Domain = _L1Domain;
        mailBox = _mailBox;
    }
    function init(address _L2Governor, address _L1VoteDelegator) external onlyOwner{
        L2Governor = _L2Governor;
        L1VoteDelegator = _L1VoteDelegator;
    }
    function bridgeVotes(uint256 _proposalId) external payable{
        uint256 proposalDeadlineBlock = IL2Governor(L2Governor).proposalDeadline(_proposalId);
        require(block.number >= proposalDeadlineBlock, "Wait till the proposal deadline is over to export the votes !!");
        (uint256 aganistVotes, uint256 forVotes, uint256 abstainVotes) = IL2Governor(L2Governor).proposalVotes(_proposalId);
        
        uint256 quote = IMailbox(mailBox).quoteDispatch(
            L1Domain,
            addressToBytes32(L1VoteDelegator),
            abi.encode(_proposalId, abi.encodePacked(uint128(aganistVotes), uint128(forVotes), uint128(abstainVotes)))
        );
        IMailbox(mailBox).dispatch{value: quote}(
            L1Domain,
            addressToBytes32(L1VoteDelegator),
            abi.encode(_proposalId, abi.encodePacked(uint128(aganistVotes), uint128(forVotes), uint128(abstainVotes)))
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
