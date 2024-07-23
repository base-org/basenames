//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {BaseRegistrar} from "src/L2/BaseRegistrar.sol";
import "forge-std/Script.sol";

/// @title Script for autonomously reserving names with a controller-permissioned pkey
///
/// @notice addr(PREMINT_PRIVATE_KEY) must be an approved `controller` on the BaseRegistrar
contract Premint is Script {
    uint256 premintPrivateKey = vm.envUint("PREMINT_PRIVATE_KEY");
    address BASE_REGISTRAR = vm.envAddress("BASE_REGISTRAR_ADDR");
    address BASE_ECOSYSTEM_MULTISIG = vm.envAddress("BASE_ECOSYSTEM_MULTISIG");

    uint256 duration = 36500 days;

    function run(string memory name) external {
        console.log("-------------------------------");
        console.log("Minting name:");
        console.log(name);
        console.log("-------------------------------");

        vm.startBroadcast(premintPrivateKey);

        bytes32 label = keccak256(bytes(name));
        uint256 id = uint256(label);

        BaseRegistrar(BASE_REGISTRAR).registerOnly(id, BASE_ECOSYSTEM_MULTISIG, duration);
    }
}
