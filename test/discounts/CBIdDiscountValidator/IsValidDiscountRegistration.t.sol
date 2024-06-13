//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {CBIdDiscountValidatorBase} from "./CBIdDiscountValidatorBase.t.sol";

contract IsValidDiscountRegistration is CBIdDiscountValidatorBase {
    function test_returnsFalse_forInvalidProof(address claimer) public view {
        vm.assume(claimer != bob);
        bytes memory data = abi.encode(bobProof);
        assertFalse(validator.isValidDiscountRegistration(claimer, data));
    }

    function test_returnsTrue_forValidProof() public view {
        bytes memory bobData = abi.encode(bobProof);
        assertTrue(validator.isValidDiscountRegistration(bob, bobData));
        bytes memory codieData = abi.encode(codieProof);
        assertTrue(validator.isValidDiscountRegistration(codie, codieData));
    }
}
