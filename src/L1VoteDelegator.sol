// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

interface IL1Governor{
    function castVoteWithReasonAndParams(
        uint256 proposalId,
        uint8 support,
        string calldata reason,
        bytes memory params
    ) external returns (uint256);
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
        bytes32 messageId = IMailBox(mailBox).dispatch(
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
        IL1Governor(L1Governor).castVoteWithReasonAndParams(proposalId, 0, "", data);
    }
    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }
    function bytes32ToAddress(bytes32 _buf) internal pure returns (address) {
        return address(uint160(uint256(_buf)));
    }
    receive() payable external{}
}