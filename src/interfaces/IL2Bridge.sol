// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IL2Bridge{

    function init(address _L2Governor, address _L1VoteDelegator) external;

    function bridgeVotes(uint256 _proposalId) external payable;

}