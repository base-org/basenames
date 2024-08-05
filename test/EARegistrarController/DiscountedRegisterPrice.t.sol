// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {EARegistrarControllerBase} from "./EARegistrarControllerBase.t.sol";
import {EARegistrarController} from "src/L2/EARegistrarController.sol";
import {IPriceOracle} from "src/L2/interface/IPriceOracle.sol";

contract DiscountedRegisterPrice is EARegistrarControllerBase {
    function test_returnsADiscountedPrice_whenThePriceIsGreaterThanTheDiscount(uint256 price) public {
        vm.assume(price > discountAmount);
        prices.setPrice(name, IPriceOracle.Price({base: price, premium: 0}));
        vm.prank(owner);
        controller.setDiscountDetails(_getDefaultDiscount());

        uint256 expectedPrice = price - discountAmount;
        uint256 retPrice = controller.discountedRegisterPrice(name, duration, discountKey);
        assertEq(retPrice, expectedPrice);
    }

    function test_returnsZero_whenThePriceIsLessThanOrEqualToTheDiscount(uint256 price) public {
        vm.assume(price <= discountAmount && price > 0);
        prices.setPrice(name, IPriceOracle.Price({base: price, premium: 0}));
        vm.prank(owner);
        controller.setDiscountDetails(_getDefaultDiscount());

        uint256 retPrice = controller.discountedRegisterPrice(name, duration, discountKey);
        assertEq(retPrice, 0);
    }
}
