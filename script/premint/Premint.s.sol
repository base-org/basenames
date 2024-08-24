//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {BaseRegistrar} from "src/L2/BaseRegistrar.sol";
import {RegistrarController} from "src/L2/RegistrarController.sol";
import {LibString} from "solady/utils/LibString.sol";

import "forge-std/Script.sol";

/// @title Script for autonomously reserving names with a controller-permissioned pkey
///
/// @notice addr(PREMINT_PRIVATE_KEY) must be an approved `controller` on the BaseRegistrar
contract Premint is Script {
    uint256 premintPrivateKey = vm.envUint("PREMINT_PRIVATE_KEY");
    address BASE_REGISTRAR = vm.envAddress("BASE_REGISTRAR_ADDR");
    address BASE_ECOSYSTEM_MULTISIG = vm.envAddress("BASE_ECOSYSTEM_MULTISIG");
    address REGISTRAR_CONTROLLER = vm.envAddress("REGISTRAR_CONTROLLER_ADDR");

    function run(string memory name, uint256 duration) external {
        console.log("-------------------------------");
        console.log("Minting name:");
        console.log(name);
        console.log("-------------------------------");

        vm.startBroadcast(premintPrivateKey);

        bytes32 label = keccak256(bytes(name));
        uint256 id = uint256(label);

        if (!BaseRegistrar(BASE_REGISTRAR).isAvailable(id)) {
            console.log("Name already registered");
            return;
        }

        // Premint name
        BaseRegistrar(BASE_REGISTRAR).registerOnly(id, BASE_ECOSYSTEM_MULTISIG, duration);

        // Record name and id in csv
        string memory idStr = vm.toString(id);
        string memory data = LibString.concat(name, ",");
        data = LibString.concat(data, idStr);
        data = LibString.concat(data, "\n");
        string[] memory input = new string[](3);
        input[0] = "python3";
        input[1] = "py/writer.py";
        input[2] = data;
        vm.ffi(input);
    }

    function verify(uint256 lines, string calldata file) public view {
        for (uint256 i; i < lines; i++) {
            string memory name = vm.readLine(file);
            bytes32 label = keccak256(bytes(name));
            uint256 id = uint256(label);
            if (BaseRegistrar(BASE_REGISTRAR).nameExpires(id) == 0) {
                console.log("Not minted: ", name);
            } else if (BaseRegistrar(BASE_REGISTRAR).ownerOf(id) != BASE_ECOSYSTEM_MULTISIG) {
                console.log("Not owned by ecosystem multisig", name);
            }
        }
    }
}
