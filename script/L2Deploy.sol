// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/GovernorCountingFractional.sol";
import "../src/L2Bridge.sol"; 

contract L2Deploy is Script{
    function run() external{
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address[] memory demoAddress = new address[](2);
        TimelockController timelockContract = new TimelockController(0, demoAddress, demoAddress, 0xbA46496e7E5A61a7A9DF5e54Ea330aD20C006d00);
        GovernorCountingFractional governorContract = new GovernorCountingFractional(IVotes(0x08a1A839544eD1Be15c04E18291c08F1c9863620), timelockContract, 250);
        L2Bridge bridgeContract = new L2Bridge(0xCC737a94FecaeC165AbCf12dED095BB13F037685, 0xF90cB82a76492614D07B82a7658917f3aC811Ac1, uint32(vm.envUint("L1_DOMAIN")));
        console.log("L2 Governor Contract Address is :- ", address(governorContract));
        console.log("L2 Bridge Contract Address is :- ", address(bridgeContract));
        vm.stopBroadcast();
    }
}