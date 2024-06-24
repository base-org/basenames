// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {RegistrarControllerBase} from "./RegistrarControllerBase.t.sol";
import {RegistrarController} from "src/L2/RegistrarController.sol";
import {Ownable} from "solady/auth/Ownable.sol";

contract SetPaymentReceiver is RegistrarControllerBase {
    function test_reverts_ifCalledByNonOwner(address caller) public {
        vm.assume(caller != owner);
        vm.expectRevert(Ownable.Unauthorized.selector);
        vm.prank(caller);
        controller.setPaymentReceiver(caller);
    }

    function test_allowsTheOwner_toSetThePaymentReceiver(address newReceiver) public {
        vm.assume(newReceiver != address(0));
        vm.expectEmit(address(controller));
        emit RegistrarController.PayemntReceiverUpdated(newReceiver);
        vm.prank(owner);
        controller.setPaymentReceiver(newReceiver);
        assertEq(newReceiver, controller.paymentReceiver());
    }
}
