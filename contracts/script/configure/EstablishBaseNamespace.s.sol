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

        address ensAddress = 0x1d3C6Cf6737921c798f07Cd6469A72f173166657; // deployer-owned registry
        Registry registry = Registry(ensAddress);
        address baseRegistrar = 0x0Cff05B4e1DF41fB5423448d4fDC81eB9Bef21df; // base registrar must own 2LD 

        // establish the base.eth namespace
        bytes32 ethLabel = keccak256("eth");
        bytes32 baseLabel = keccak256("basetest"); // basetest.eth is our sepolia test domain 
        registry.setSubnodeOwner(0x0, ethLabel, deployerAddress);
        registry.setSubnodeOwner(ETH_NODE, baseLabel, baseRegistrar);

        vm.stopBroadcast();
    }
}
