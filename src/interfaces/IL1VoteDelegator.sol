// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IL1VoteDelegator{

    function init(address _L1Governor, address _L2Bridge) external;

    function bridgeProposal(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description) external payable;

}