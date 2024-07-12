// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import {Registry} from "src/L2/Registry.sol";
import "src/util/Constants.sol";

contract EstablishReverseNamespace is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        address ensAddress = vm.envAddress("REGISTRY_ADDR"); // deployer-owned registry
        Registry registry = Registry(ensAddress);
        address reverse = vm.envAddress("REVERSE_REGISTRAR_ADDR"); // Reverse registrar

        // establish the base.eth namespace
        bytes32 reverseLabel = keccak256("reverse");
        bytes32 addrLabel = keccak256("addr"); // basetest.eth is our sepolia test domain
        registry.setSubnodeOwner(0x0, reverseLabel, deployerAddress);
        registry.setSubnodeOwner(REVERSE_NODE, addrLabel, address(reverse)); // reverse registrar must own addr.reverse

        vm.stopBroadcast();
    }
}
