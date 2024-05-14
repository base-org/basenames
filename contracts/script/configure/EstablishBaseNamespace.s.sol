// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import {Registry} from "src/L2/Registry.sol";
import "src/util/Constants.sol";

contract EstablishNamespaces is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        address ensAddress = 0xBD69dd64b94fe7435157F4851e4b4Aa3A0988c90; // deployer-owned registry
        Registry registry = Registry(ensAddress);

        // establish the base.eth namespace
        bytes32 ethLabel = keccak256("eth");
        bytes32 baseLabel = keccak256("base");
        registry.setSubnodeOwner(0x0, ethLabel, deployerAddress);
        registry.setSubnodeOwner(ETH_NODE, baseLabel, deployerAddress);

        vm.stopBroadcast();
    }
}
