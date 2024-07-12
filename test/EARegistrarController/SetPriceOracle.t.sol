// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {EARegistrarControllerBase} from "./EARegistrarControllerBase.t.sol";
import {EARegistrarController} from "src/L2/EARegistrarController.sol";
import {MockPriceOracle} from "test/mocks/MockPriceOracle.sol";
import {IPriceOracle} from "src/L2/interface/IPriceOracle.sol";
import {Ownable} from "solady/auth/Ownable.sol";

contract SetPriceOracle is EARegistrarControllerBase {
    function test_reverts_ifCalledByNonOwner(address caller) public {
        vm.assume(caller != owner);
        MockPriceOracle newPrices = new MockPriceOracle();
        vm.expectRevert(Ownable.Unauthorized.selector);
        vm.prank(caller);
        controller.setPriceOracle(IPriceOracle(address(newPrices)));
    }

    function test_setsThePriceOracleAccordingly() public {
        vm.expectEmit();
        MockPriceOracle newPrices = new MockPriceOracle();
        emit EARegistrarController.PriceOracleUpdated(address(newPrices));
        vm.prank(owner);
        controller.setPriceOracle(IPriceOracle(address(newPrices)));
        assertEq(address(controller.prices()), address(newPrices));
    }
}
