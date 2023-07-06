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
        address collateralContractAddress = "L1 Collateral Contract Address";
        address L1VoteDelegatorAddress = "L1VoteDelegator Contract Address";
        address L1GovernorAddress = "L1Governor Contract Address";
        address L2BridgeAddress = "L2 Bridge Contract Address";
        IHypERC20CollateralVotable(collateralContractAddress).delegateVotes(L1VoteDelegatorAddress);
        IL1VoteDelegator(L1VoteDelegatorAddress).init(L1GovernorAddress, L2BridgeAddress);
        vm.stopBroadcast();
    }
}