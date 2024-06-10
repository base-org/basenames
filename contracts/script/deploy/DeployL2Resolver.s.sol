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
        vm.startBroadcast(deployerPrivateKey);

        /// L2 Resolver constructor data
        address ensAddress = 0x1d3C6Cf6737921c798f07Cd6469A72f173166657; // deployer-owned registry
        address controller = 0x915b28fC104b09E3Cc8363bdAa31E6862c39f7FE; // let deployer manage names
        address reverse = 0x6864841F1cD70349F23126982C140676268612F9; // deployer-owned rev registrar

        L2Resolver l2 = new L2Resolver(Registry(ensAddress), controller, reverse);

        console.log(address(l2));

        vm.stopBroadcast();
    }
}
