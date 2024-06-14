// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import {Registry} from "src/L2/Registry.sol";
import {ENS} from "ens-contracts/registry/ENS.sol";
import {ETH_NODE, BASE_ETH_NODE} from "src/util/Constants.sol";
import {NameEncoder} from "ens-contracts/utils/NameEncoder.sol";
import {RegistryBase} from "./RegistryBase.t.sol";

contract RecordExists is RegistryBase {
    function test_correctlyConfirmsARecordExists() public view {
        assertTrue(registry.recordExists(BASE_ETH_NODE));
    }

    function text_correctlyConfirmsARecordDoesNotExist(bytes32 node) public view {
        vm.assume(node != BASE_ETH_NODE && node != ETH_NODE && node != bytes32(0));
        assertFalse(registry.recordExists(node));
    }
}
