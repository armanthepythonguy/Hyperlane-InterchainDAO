// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/GovernorCountingFractional.sol";
import "../src/L1VoteDelegator.sol";

contract L1Deploy is Script{
    function run() external{
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address[] memory demoAddress = new address[](2);
        TimelockController timelockContract = new TimelockController(0, demoAddress, demoAddress, 0xbA46496e7E5A61a7A9DF5e54Ea330aD20C006d00); // Replace this address with your own
        L1VoteDelegator delegatorContract = new L1VoteDelegator(0xCC737a94FecaeC165AbCf12dED095BB13F037685, 0xF90cB82a76492614D07B82a7658917f3aC811Ac1, uint32(vm.envUint("L2_DOMAIN")));
        GovernorCountingFractional governorContract = new GovernorCountingFractional(IVotes(0x3e450468bCb3757AbBA7406f1E3bF126982d5c79 /* Replace this address with L1TokenAddress*/), timelockContract, 450);
        console.log("L1 Governor Contract Address is :- ", address(governorContract));
        console.log("L1 Vote Delegator Contract Address is :- ", address(delegatorContract));
        vm.stopBroadcast();
    }
}