// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/interfaces/IL2Bridge.sol";


contract L2BridgeVote is Script{
    function run() external{
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address L2BridgeAddress = 0x2556A13cCfb4707325F8141fA98C670e9d0e1e8D; // Replace with L2BridgeAddress
        uint256 proposalId = 38930444180836860895355375845097488751844867845777537458460374360909120620526; // Replace with proposalId
        IL2Bridge(L2BridgeAddress).bridgeVotes{value: 0.1 ether}(proposalId);
        vm.stopBroadcast();
    }
}