// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "../src/L2GovernorCountingFractional.sol";
import "../src/L2Bridge.sol"; 

contract L2Deploy is Script{
    function run() external{
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address[] memory demoAddress = new address[](2);
        TimelockController timelockContract = new TimelockController(0, demoAddress, demoAddress, 0xbA46496e7E5A61a7A9DF5e54Ea330aD20C006d00);
        L2GovernorCountingFractional governorContract = new L2GovernorCountingFractional(IVotes(0x08a1A839544eD1Be15c04E18291c08F1c9863620), timelockContract);
        L2Bridge bridgeContract = new L2Bridge(0xCC737a94FecaeC165AbCf12dED095BB13F037685, 0xF90cB82a76492614D07B82a7658917f3aC811Ac1, 80001);

        vm.stopBroadcast();
    }
}