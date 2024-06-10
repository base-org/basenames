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
        address ensAddress = 0xBD69dd64b94fe7435157F4851e4b4Aa3A0988c90; // deployer-owned registry
        address controller = 0x0; // let deployer manage names
        address reverse = 0x5F15c3B5949F5767F5Ca9013a8E4Ca4D97a053eD; // deployer-owned rev registrar

        L2Resolver l2 = new L2Resolver(Registry(ensAddress), controller, reverse);

        console.log(address(l2));

        vm.stopBroadcast();
    }
}
