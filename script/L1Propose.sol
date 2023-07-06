// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/interfaces/IL1VoteDelegator.sol";
import "@openzeppelin/contracts/governance/IGovernor.sol";


contract L1Propose is Script{
    function run() external{
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address L1GovernorAddress = "L1 Governor Address";
        address[] memory targets = new address[](1);
        targets[0] = 0xbA46496e7E5A61a7A9DF5e54Ea330aD20C006d00;
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        string memory description = "Demo proposal 3";
        IGovernor(L1GovernorAddress).propose(targets, values, calldatas, description);
        vm.stopBroadcast();
    }
}