// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {RegistrarControllerBase} from "./RegistrarControllerBase.t.sol";
import {RegistrarController} from "src/L2/RegistrarController.sol";
import {MockReverseRegistrar} from "test/mocks/MockReverseRegistrar.sol";
import {IReverseRegistrar} from "src/L2/interface/IReverseRegistrar.sol";
import {Ownable} from "solady/auth/Ownable.sol";

contract SetReverseRegistrar is RegistrarControllerBase {
    function test_reverts_ifCalledByNonOwner(address caller) public {
        vm.assume(caller != owner);
        MockReverseRegistrar newReverse = new MockReverseRegistrar();
        vm.expectRevert(Ownable.Unauthorized.selector);
        vm.prank(caller);
        controller.setReverseRegistrar(IReverseRegistrar(address(newReverse)));
    }

    function test_setsTheReverseRegistrarAccordingly() public {
        vm.expectEmit();
        MockReverseRegistrar newReverse = new MockReverseRegistrar();
        emit RegistrarController.ReverseRegistrarUpdated(address(newReverse));
        vm.prank(owner);
        controller.setReverseRegistrar(IReverseRegistrar(address(newReverse)));
        assertEq(address(controller.reverseRegistrar()), address(newReverse));
    }
}
