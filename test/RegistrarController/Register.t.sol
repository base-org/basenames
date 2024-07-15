// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {RegistrarControllerBase} from "./RegistrarControllerBase.t.sol";
import {RegistrarController} from "src/L2/RegistrarController.sol";
import {IPriceOracle} from "src/L2/interface/IPriceOracle.sol";

contract Register is RegistrarControllerBase {
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

    function test_reverts_whenValueTooSmall() public {
        vm.deal(user, 1 ether);
        uint256 price = controller.registerPrice(name, duration);
        base.setAvailable(uint256(nameLabel), true);
        vm.expectRevert(RegistrarController.InsufficientValue.selector);
        vm.prank(user);
        controller.register{value: price - 1}(_getDefaultRegisterRequest());
    }

    function test_registersSuccessfully() public {
        vm.deal(user, 1 ether);
        RegistrarController.RegisterRequest memory request = _getDefaultRegisterRequest();

        base.setAvailable(uint256(nameLabel), true);
        uint256 expires = block.timestamp + request.duration;
        base.setNameExpires(uint256(nameLabel), expires);
        uint256 price = controller.registerPrice(request.name, request.duration);

        vm.expectEmit(address(controller));
        emit RegistrarController.ETHPaymentProcessed(user, price);
        vm.expectEmit(address(controller));
        emit RegistrarController.NameRegistered(request.name, nameLabel, user, expires);

        vm.prank(user);
        controller.register{value: price}(request);

        bytes memory retByte = resolver.firstBytes();
        assertEq(keccak256(retByte), keccak256(request.data[0]));
        assertTrue(reverse.hasClaimed(user));
    }

    function test_sendsARefund_ifUserOverpayed() public {
        vm.deal(user, 1 ether);
        RegistrarController.RegisterRequest memory request = _getDefaultRegisterRequest();

        base.setAvailable(uint256(nameLabel), true);
        uint256 expires = block.timestamp + request.duration;
        base.setNameExpires(uint256(nameLabel), expires);
        uint256 price = controller.registerPrice(request.name, request.duration);

        vm.prank(user);
        controller.register{value: price + 1}(request);

        uint256 expectedBalance = 1 ether - price;
        assertEq(user.balance, expectedBalance);
    }
}
