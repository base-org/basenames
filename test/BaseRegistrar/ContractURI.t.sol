//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {BaseRegistrarBase} from "./BaseRegistrarBase.t.sol";

contract ContractURI is BaseRegistrarBase {
    function test_contractURI_isReturnedAsExpected() public view {
        assertEq(keccak256(bytes(baseRegistrar.contractURI())), keccak256(bytes(collectionURI)));
    }
}
