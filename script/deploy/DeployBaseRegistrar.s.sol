// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import {ENS} from "ens-contracts/registry/ENS.sol";

import {BASE_ETH_NODE} from "src/util/Constants.sol";
import {BaseRegistrar} from "src/L2/BaseRegistrar.sol";
import {NameEncoder} from "ens-contracts/utils/NameEncoder.sol";

contract DeployBaseRegistrar is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        /// L2 Resolver constructor data
        address ensAddress = vm.envAddress("REGISTRY_ADDR"); // deployer-owned registry
        (, bytes32 node) = NameEncoder.dnsEncodeName("basetest.eth");

        BaseRegistrar base = new BaseRegistrar(ENS(ensAddress), deployerAddress, node, "", "");

        console.log("Base Registrar deployed to:");
        console.log(address(base));

        vm.stopBroadcast();
    }
}
