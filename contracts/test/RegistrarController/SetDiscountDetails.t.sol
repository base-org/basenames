// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {RegistrarControllerBase} from "./RegistrarControllerBase.t.sol";
import {RegistrarController} from "src/L2/RegistrarController.sol";
import {Ownable} from "solady/auth/Ownable.sol";

contract SetDiscountDetails is RegistrarControllerBase {
    function test_reverts_ifCalledByNonOwner(address caller) public {
        vm.assume(caller != owner);
        vm.expectRevert(Ownable.Unauthorized.selector);
        vm.prank(caller);
        controller.setDiscountDetails(discountKey, _getDefaultDiscount());
    }

    function test_reverts_ifTheDiscountIsZero() public {
        RegistrarController.DiscountDetails memory noDiscount = _getDefaultDiscount();
        noDiscount.discount = 0;
        vm.expectRevert(abi.encodeWithSelector(RegistrarController.InvalidDiscountAmount.selector, discountKey, 0));
        vm.prank(owner);
        controller.setDiscountDetails(discountKey, noDiscount);
    }

    function test_reverts_ifTheDiscountKeysMismatch() public {
        RegistrarController.DiscountDetails memory badKeyDetails = _getDefaultDiscount();
        bytes32 badKey = bytes32(0);
        badKeyDetails.key = badKey;
        vm.expectRevert(abi.encodeWithSelector(RegistrarController.DiscountKeyMismatch.selector, discountKey, badKey));
        vm.prank(owner);
        controller.setDiscountDetails(discountKey, badKeyDetails);
    }

    function test_reverts_ifTheDiscounValidatorIsInvalid() public {
        RegistrarController.DiscountDetails memory noValidator = _getDefaultDiscount();
        noValidator.discountValidator = address(0);
        vm.expectRevert(abi.encodeWithSelector(RegistrarController.InvalidValidator.selector, discountKey, address(0)));
        vm.prank(owner);
        controller.setDiscountDetails(discountKey, noValidator);
    }

    function test_setsTheDetailsAccordingly() public {
        vm.expectEmit(address(controller));
        emit RegistrarController.DiscountUpdated(discountKey, _getDefaultDiscount());
        vm.prank(owner);
        controller.setDiscountDetails(discountKey, _getDefaultDiscount());
        (bool retActive, address retValidator, bytes32 retKey, uint256 retDiscount) = controller.discounts(discountKey);
        assertTrue(retActive);
        assertEq(retValidator, address(validator));
        assertEq(retKey, discountKey);
        assertEq(retDiscount, discountAmount);
    }

    function test_addsAndRemoves_fromActiveDiscounts() public {
        RegistrarController.DiscountDetails memory discountDetails = _getDefaultDiscount();

        vm.prank(owner);
        controller.setDiscountDetails(discountKey, discountDetails);
        RegistrarController.DiscountDetails[] memory activeDiscountsWithActive = controller.getActiveDiscounts();
        assertEq(activeDiscountsWithActive.length, 1);
        assertTrue(activeDiscountsWithActive[0].active);
        assertEq(activeDiscountsWithActive[0].discountValidator, address(validator));
        assertEq(activeDiscountsWithActive[0].key, discountKey);
        assertEq(activeDiscountsWithActive[0].discount, discountAmount);

        discountDetails.active = false;
        vm.prank(owner);
        controller.setDiscountDetails(discountKey, discountDetails);
        RegistrarController.DiscountDetails[] memory activeDiscountsNoneActive = controller.getActiveDiscounts();
        assertEq(activeDiscountsNoneActive.length, 0);
    }
}
