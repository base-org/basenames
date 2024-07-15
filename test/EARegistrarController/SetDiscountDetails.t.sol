// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {EARegistrarControllerBase} from "./EARegistrarControllerBase.t.sol";
import {EARegistrarController} from "src/L2/EARegistrarController.sol";
import {Ownable} from "solady/auth/Ownable.sol";

contract SetDiscountDetails is EARegistrarControllerBase {
    function test_reverts_ifCalledByNonOwner(address caller) public {
        vm.assume(caller != owner);
        vm.expectRevert(Ownable.Unauthorized.selector);
        vm.prank(caller);
        controller.setDiscountDetails(_getDefaultDiscount());
    }

    function test_reverts_ifTheDiscountIsZero() public {
        EARegistrarController.DiscountDetails memory noDiscount = _getDefaultDiscount();
        noDiscount.discount = 0;
        vm.expectRevert(abi.encodeWithSelector(EARegistrarController.InvalidDiscountAmount.selector, discountKey));
        vm.prank(owner);
        controller.setDiscountDetails(noDiscount);
    }

    function test_reverts_ifTheDiscounValidatorIsInvalid() public {
        EARegistrarController.DiscountDetails memory noValidator = _getDefaultDiscount();
        noValidator.discountValidator = address(0);
        vm.expectRevert(
            abi.encodeWithSelector(EARegistrarController.InvalidValidator.selector, discountKey, address(0))
        );
        vm.prank(owner);
        controller.setDiscountDetails(noValidator);
    }

    function test_setsTheDetailsAccordingly() public {
        vm.expectEmit(address(controller));
        emit EARegistrarController.DiscountUpdated(discountKey, _getDefaultDiscount());
        vm.prank(owner);
        controller.setDiscountDetails(_getDefaultDiscount());
        (bool retActive, address retValidator, bytes32 retKey, uint256 retDiscount) = controller.discounts(discountKey);
        assertTrue(retActive);
        assertEq(retValidator, address(validator));
        assertEq(retKey, discountKey);
        assertEq(retDiscount, discountAmount);
    }

    function test_addsAndRemoves_fromActiveDiscounts() public {
        EARegistrarController.DiscountDetails memory discountDetails = _getDefaultDiscount();

        vm.prank(owner);
        controller.setDiscountDetails(discountDetails);
        EARegistrarController.DiscountDetails[] memory activeDiscountsWithActive = controller.getActiveDiscounts();
        assertEq(activeDiscountsWithActive.length, 1);
        assertTrue(activeDiscountsWithActive[0].active);
        assertEq(activeDiscountsWithActive[0].discountValidator, address(validator));
        assertEq(activeDiscountsWithActive[0].key, discountKey);
        assertEq(activeDiscountsWithActive[0].discount, discountAmount);

        discountDetails.active = false;
        vm.prank(owner);
        controller.setDiscountDetails(discountDetails);
        EARegistrarController.DiscountDetails[] memory activeDiscountsNoneActive = controller.getActiveDiscounts();
        assertEq(activeDiscountsNoneActive.length, 0);
    }
}
