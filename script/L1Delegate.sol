// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/interfaces/IL1VoteDelegator.sol";


contract L1Delegate is Script{
    function run() external{
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address L1VoteDelegatorAddress = "L1VoteDelegatorAddress";
        address[] memory targets = new address[](1);
        targets[0] = 0xbA46496e7E5A61a7A9DF5e54Ea330aD20C006d00;
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        string memory description = "Demo proposal 3";
        IL1VoteDelegator(L1VoteDelegatorAddress).bridgeProposal{value: 0.1 ether}(targets, values, calldatas, description);
        vm.stopBroadcast();
    }
}