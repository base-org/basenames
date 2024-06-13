// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";

import {NameEncoder} from "ens-contracts/utils/NameEncoder.sol";

import "src/L2/L2Resolver.sol";
import {Registry} from "src/L2/Registry.sol";
import "src/util/Constants.sol";

contract DeployL2Resolver is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        /// L2 Resolver constructor data
        address ensAddress = vm.envAddress("REGISTRY_ADDR");
        address controller = vm.envAddress("REGISTRAR_CONTROLLER_ADDR"); // controller can set data on deployment
        address reverse = vm.envAddress("REVERSE_REGISTRAR_ADDR");

        L2Resolver l2 = new L2Resolver(Registry(ensAddress), controller, reverse, deployerAddress);

        console.log(address(l2));

        vm.stopBroadcast();
    }
}
