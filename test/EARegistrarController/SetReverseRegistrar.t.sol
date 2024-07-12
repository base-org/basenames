// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {EARegistrarControllerBase} from "./EARegistrarControllerBase.t.sol";
import {EARegistrarController} from "src/L2/EARegistrarController.sol";
import {MockReverseRegistrar} from "test/mocks/MockReverseRegistrar.sol";
import {IReverseRegistrar} from "src/L2/interface/IReverseRegistrar.sol";
import {Ownable} from "solady/auth/Ownable.sol";

contract SetReverseRegistrar is EARegistrarControllerBase {
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
        emit EARegistrarController.ReverseRegistrarUpdated(address(newReverse));
        vm.prank(owner);
        controller.setReverseRegistrar(IReverseRegistrar(address(newReverse)));
        assertEq(address(controller.reverseRegistrar()), address(newReverse));
    }
}
