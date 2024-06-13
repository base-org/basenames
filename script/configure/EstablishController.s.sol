// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import {BaseRegistrar} from "src/L2/BaseRegistrar.sol";

contract AddDiscountValidator is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address base = vm.envAddress("BASE_REGISTRAR_ADDR");
        address controller = vm.envAddress("REGISTRAR_CONTROLLER_ADDR");
        BaseRegistrar(base).addController(controller);
        vm.stopBroadcast();
    }
}
