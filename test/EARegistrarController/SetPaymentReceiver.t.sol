// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {EARegistrarControllerBase} from "./EARegistrarControllerBase.t.sol";
import {EARegistrarController} from "src/L2/EARegistrarController.sol";
import {Ownable} from "solady/auth/Ownable.sol";

contract SetPaymentReceiver is EARegistrarControllerBase {
    function test_reverts_ifCalledByNonOwner(address caller) public {
        vm.assume(caller != owner && caller != address(0));
        vm.expectRevert(Ownable.Unauthorized.selector);
        vm.prank(caller);
        controller.setPaymentReceiver(caller);
    }

    function test_reverts_ifNewPaymentReceiver_isZeroAddress() public {
        vm.expectRevert(EARegistrarController.InvalidPaymentReceiver.selector);
        vm.prank(owner);
        controller.setPaymentReceiver(address(0));
    }

    function test_allowsTheOwner_toSetThePaymentReceiver(address newReceiver) public {
        vm.assume(newReceiver != address(0));
        vm.expectEmit(address(controller));
        emit EARegistrarController.PaymentReceiverUpdated(newReceiver);
        vm.prank(owner);
        controller.setPaymentReceiver(newReceiver);
        assertEq(newReceiver, controller.paymentReceiver());
    }
}
