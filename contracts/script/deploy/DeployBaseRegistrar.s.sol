// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import {ENS} from "ens-contracts/registry/ENS.sol";

import {BASE_ETH_NODE} from "src/util/Constants.sol";
import {BaseRegistrar} from "src/L2/BaseRegistrar.sol";


contract DeployBaseRegistrar is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        /// L2 Resolver constructor data
        address ensAddress = 0x1d3C6Cf6737921c798f07Cd6469A72f173166657; // deployer-owned registry

        BaseRegistrar base = new BaseRegistrar(ENS(ensAddress), deployerAddress, BASE_ETH_NODE);

        console.log("Base Registrar deployed to:");
        console.log(address(base));

        vm.stopBroadcast();
    }
}
