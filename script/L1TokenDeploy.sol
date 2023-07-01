// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/L1Token.sol";

contract L1TokenDeploy is Script{
    function run() external{
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        L1Token tokenContract = new L1Token(1000000000000000000000000, 0);
        console.log("The L1 Token Contract Address is :- ",address(tokenContract));

        vm.stopBroadcast();
    }
}