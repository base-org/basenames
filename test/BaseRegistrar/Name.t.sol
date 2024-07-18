//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {BaseRegistrarBase} from "./BaseRegistrarBase.t.sol";

contract Name is BaseRegistrarBase {
    function test_nameIsSetAsExpected() public view {
        string memory expectedName = "Basenames";
        assertEq(keccak256(bytes(baseRegistrar.name())), keccak256(bytes(expectedName)));
    }
}
