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
        TimelockController timelockContract = new TimelockController(0, demoAddress, demoAddress, 0xbA46496e7E5A61a7A9DF5e54Ea330aD20C006d00);
        L1VoteDelegator delegatorContract = new L1VoteDelegator(0xCC737a94FecaeC165AbCf12dED095BB13F037685, 0xF90cB82a76492614D07B82a7658917f3aC811Ac1, 43113);
        GovernorCountingFractional governorContract = new GovernorCountingFractional(IVotes(0x21f001e1Ea191B65aA7C70AD4c13f093D1fdaA54), timelockContract);
        console.log("L1 Governor Contract Address is :- ", address(governorContract));
        console.log("L1 Vote Delegator Contract Address is :- ", address(delegatorContract));
        vm.stopBroadcast();
    }
}