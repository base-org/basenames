//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {CBIdDiscountValidator} from "src/L2/discounts/CBIdDiscountValidator.sol";

contract CBIdDiscountValidatorBase is Test {
    CBIdDiscountValidator public validator;

    address public owner = makeAddr("owner");
    address ace = address(0xace);
    address bob = address(0xb0b);
    address codie = address(0xc0d1e);

    bytes32 public root = 0x17b5b2e0a6979fb8c0e55a25fd3f2dbf6d147e5ad04d79d9e272c3dd1706219a; // tree contains bob and codie

    bytes32[] public bobProof = [bytes32(0x789d8ab94963f94f7fbef2c39fc1c79a810770640e2d061d775eea4b24b255c0)];
    bytes32[] public codieProof = [bytes32(0x3034df95d8f0ea7db7ab950e22fc977fa82ae80174df73ee1c75c24246b96df3)];

    function setUp() public {
        validator = new CBIdDiscountValidator(owner, root);
    }
}
