// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IL1VoteDelegator{
    function bridgeProposal(bytes memory _data) external;
}