// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {RegistrarControllerBase} from "./RegistrarControllerBase.t.sol";
import {RegistrarController} from "src/L2/RegistrarController.sol";
import {IPriceOracle} from "src/L2/interface/IPriceOracle.sol";

contract RegisterPrice is RegistrarControllerBase {

    function test_reverts_whenResolverRequiredAndNotSupplied() public {
        vm.deal(user, 1 ether);
        uint256 price = controller.registerPrice(name, duration);
        vm.expectRevert(RegistrarController.ResolverRequiredWhenDataSupplied.selector);
        vm.prank(user);
        RegistrarController.RegisterRequest memory noResolverRequest = _getDefaultRegisterRequest();
        noResolverRequest.resolver = address(0);
        controller.register{value: price}(noResolverRequest);
    }

    function test_reverts_whenNameNotAvailble() public {
        vm.deal(user, 1 ether);
        uint256 price = controller.registerPrice(name, duration);
        base.setAvailable(uint256(nameLabel), false);
        vm.expectRevert(abi.encodeWithSelector(RegistrarController.NameNotAvailable.selector, name));
        vm.prank(user);
        controller.register{value: price}(_getDefaultRegisterRequest());
    }

    function test_reverts_whenDurationTooShort() public {
        vm.deal(user, 1 ether);
        uint256 price = controller.registerPrice(name, duration);
        base.setAvailable(uint256(nameLabel), true);
        RegistrarController.RegisterRequest memory shortDurationRequest = _getDefaultRegisterRequest();
        uint256 shortDuration = controller.MIN_REGISTRATION_DURATION() - 1;
        shortDurationRequest.duration = shortDuration;
        vm.expectRevert(abi.encodeWithSelector(RegistrarController.DurationTooShort.selector, shortDuration));
        vm.prank(user);
        controller.register{value: price}(shortDurationRequest);
    }
}
