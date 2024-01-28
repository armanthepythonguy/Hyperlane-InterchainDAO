// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@hyperlane-xyz/core/contracts/interfaces/IMailbox.sol";
import "@openzeppelin/contracts/governance/IGovernor.sol";

contract L1VoteDelegator is Ownable{
    address public L1Governor;
    mapping(uint32 => address) public L2Bridges;
    address public mailBox;
    modifier onlyMailbox{
        require(msg.sender == mailBox, "Only mailbox can send data !!!!");
        _;
    }
    constructor(address _mailBox, address _L1Governor){
        mailBox = _mailBox;
        L1Governor = _L1Governor;
    }
    function addRemote(uint32 _domainId, address _bridge) external onlyOwner(){
        L2Bridges[_domainId] = _bridge;
    }
    function bridgeProposal(
        uint32 _L2Domain,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description) external payable{
        require(L2Bridges[_L2Domain]!=address(0), "Remote not registered !!!");
        uint256 proposalId = IGovernor(L1Governor).hashProposal(targets, values, calldatas, keccak256(bytes(description)));
        IGovernor.ProposalState proposalState = IGovernor(L1Governor).state(proposalId);
        if(proposalState == IGovernor.ProposalState.Active){
            uint256 quote = IMailbox(mailBox).quoteDispatch(
                _L2Domain,
                addressToBytes32(L2Bridges[_L2Domain]),
                abi.encode(targets, values, calldatas, description)
            );
            IMailbox(mailBox).dispatch{value: quote}(
                _L2Domain,
                addressToBytes32(L2Bridges[_L2Domain]),
                abi.encode(targets, values, calldatas, description)
            );
        }
    }
    function handle(uint32 _origin, bytes32 _sender, bytes memory _body) external onlyMailbox() {
        address sender = bytes32ToAddress(_sender);
        require(sender == L2Bridges[_origin], "Only the L2Bridge can send votes !!!");
        (uint256 proposalId, bytes memory data) = abi.decode(_body, (uint256,bytes));
        IGovernor(L1Governor).castVoteWithReasonAndParams(proposalId, 0, "", data);
    }
    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }
    function bytes32ToAddress(bytes32 _buf) internal pure returns (address) {
        return address(uint160(uint256(_buf)));
    }
    receive() payable external{}
}
