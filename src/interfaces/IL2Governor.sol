// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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