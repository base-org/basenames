// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";

import {IPriceOracle} from "src/L2/interface/IPriceOracle.sol";
import {BaseRegistrar} from "src/L2/BaseRegistrar.sol";
import {Registry} from "src/L2/Registry.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IReverseRegistrar} from "src/L2/interface/IReverseRegistrar.sol";
import {RegistrarController} from "src/L2/RegistrarController.sol";

import "src/util/Constants.sol";

contract DeployL2Resolver is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        /// L2 Resolver constructor data
        address oracle = 0x12e26f301185336A2BEc9cB8f2b87C7451ee7E95;
        address reverse = 0x5F15c3B5949F5767F5Ca9013a8E4Ca4D97a053eD; // deployer-owned rev registrar
        address base = 0x0Cff05B4e1DF41fB5423448d4fDC81eB9Bef21df; 

        RegistrarController controller = new RegistrarController(
            BaseRegistrar(base), 
            IPriceOracle(oracle), 
            IReverseRegistrar(reverse), 
            deployerAddress
        );

        console.log("RegistrarController deployed to:");
        console.log(address(controller));

        vm.stopBroadcast();
    }
}
