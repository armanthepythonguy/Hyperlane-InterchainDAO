// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@hyperlane-xyz/core/contracts/interfaces/IInterchainGasPaymaster.sol";
import "@hyperlane-xyz/core/contracts/interfaces/IMailbox.sol";
import "@openzeppelin/contracts/governance/IGovernor.sol";

contract L1VoteDelegator is Ownable{
    address public L1Governor;
    address public L2Bridge;
    uint32 public L2Domain;
    address public mailBox;
    address public interchainGasPaymaster;
    modifier onlyMailbox{
        require(msg.sender == mailBox, "Only mailbox can send data !!!!");
        _;
    }
    constructor(address _mailBox, address _interchainGasPaymaster, uint32 _L2Domain){
        L2Domain = _L2Domain;
        mailBox = _mailBox;
        interchainGasPaymaster = _interchainGasPaymaster;
    }
    function init(address _L1Governor, address _L2Bridge) external onlyOwner{
        L1Governor = _L1Governor;
        L2Bridge = _L2Bridge;
    }
    function bridgeProposal(bytes memory _data) external{
        bytes32 messageId = IMailbox(mailBox).dispatch(
            L2Domain,
            addressToBytes32(L2Bridge),
            _data
        );
        uint256 quote = IInterchainGasPaymaster(interchainGasPaymaster).quoteGasPayment(L2Domain, 200000);
        IInterchainGasPaymaster(interchainGasPaymaster).payForGas{value: quote}(
            messageId,
            L2Domain,
            200000,
            address(this)
        );
    }
    function handle(uint32 _origin, bytes32 _sender, bytes memory _body) external onlyMailbox() {
        require(_origin == L2Domain, "Only messages from L2Domain is accepted !!");
        address sender = bytes32ToAddress(_sender);
        require(sender == L2Bridge, "Only the L2Bridge can send votes !!!");
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