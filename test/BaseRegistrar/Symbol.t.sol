//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {BaseRegistrarBase} from "./BaseRegistrarBase.t.sol";

contract Symbol is BaseRegistrarBase {
    function test_nameIsSetAsExpected() public view {
        string memory expectedSymbol = "";
        assertEq(keccak256(bytes(baseRegistrar.symbol())), keccak256(bytes(expectedSymbol)));
    }
}
