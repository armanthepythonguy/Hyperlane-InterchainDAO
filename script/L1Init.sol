// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/interfaces/IHypERC20CollateralVotable.sol";
import "../src/interfaces/IL1VoteDelegator.sol";


contract L1Init is Script{
    function run() external{
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address collateralContractAddress = 0xfFf9ED502751FA23FD2ec0E1Ea29dFe73a874607; // Replace this with collateral contract address
        address L1VoteDelegatorAddress = 0x033C68A4165bCF3094F5D7C49680fe7ec21cACAF; // Replace this with L1VoteDelegatorAddress
        address L1GovernorAddress = 0xdDc03f1B3b2619cB1D67E5b2B5F3c7E4c5C295f0; // Replace with L1GovernorAddress
        address L2BridgeAddress = 0x2556A13cCfb4707325F8141fA98C670e9d0e1e8D; // Replace with L2BridgeAddress
        IHypERC20CollateralVotable(collateralContractAddress).delegateVotes(L1VoteDelegatorAddress);
        IL1VoteDelegator(L1VoteDelegatorAddress).init(L1GovernorAddress, L2BridgeAddress);
        vm.stopBroadcast();
    }
}