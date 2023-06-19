// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/L1Token.sol";
import "../src/L1GovernorCountingFractional.sol";
import "../src/L1VoteDelegator.sol";

contract L1TokenDeploy is Script{
    function run() external{
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        L1Token tokenContract = new L1Token(1000000000000000000000000, 0);

        vm.stopBroadcast();
    }
}