//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {BaseRegistrarBase} from "./BaseRegistrarBase.t.sol";

contract TokenURI is BaseRegistrarBase {
    function test_nameIsSetAsExpected() public view {
        string memory expectedURI = "";
        assertEq(keccak256(bytes(baseRegistrar.tokenURI(1))), keccak256(bytes(expectedURI)));
    }
}
