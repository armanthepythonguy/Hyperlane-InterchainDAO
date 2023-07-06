// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/interfaces/IL2Bridge.sol";

contract L2Init is Script{
    function run() external{
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address L2BridgeAddress = 0x2556A13cCfb4707325F8141fA98C670e9d0e1e8D;
        address L2GovernorAddress = 0x4B14E3e159813C9F79808f16dEdD681d09425aA6;
        address L1VoteDelegatorAddress = 0x033C68A4165bCF3094F5D7C49680fe7ec21cACAF;
        IL2Bridge(L2BridgeAddress).init(L2GovernorAddress, L1VoteDelegatorAddress);
        vm.stopBroadcast();
    }
}