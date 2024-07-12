//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ERC721DiscountValidatorBase} from "./ERC721DiscountValidatorBase.t.sol";

contract IsValidDiscountRegistration is ERC721DiscountValidatorBase {
    function test_returnsFalse_whenTheClaimerDoesNotHaveTheToken() public view {
        assertFalse(validator.isValidDiscountRegistration(userA, ""));
    }

    function test_returnsFalse_whenAnotherUserHasTheToken() public {
        token.mint(userA, 1);
        assertFalse(validator.isValidDiscountRegistration(userB, ""));
    }

    function test_returnsTrue_whenTheUserHasTheToken() public {
        token.mint(userA, 1);
        assertTrue(validator.isValidDiscountRegistration(userA, ""));
    }
}
