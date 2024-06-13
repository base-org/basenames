//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {BaseRegistrar} from "src/L2/BaseRegistrar.sol";
import {BaseRegistrarBase} from "./BaseRegistrarBase.t.sol";
import {Ownable} from "solady/auth/Ownable.sol";

contract RemoveController is BaseRegistrarBase {
    function test_allowsOwnerToRemoveController(address controller) public {
        vm.prank(owner);
        baseRegistrar.addController(controller);
        assertTrue(baseRegistrar.controllers(controller));

        vm.expectEmit();
        emit BaseRegistrar.ControllerRemoved(controller);
        vm.prank(owner);
        baseRegistrar.removeController(controller);
        assertFalse(baseRegistrar.controllers(controller));
    }

    function test_reverts_whenCalledByNonOwner(address caller) public {
        vm.assume(caller != owner);
        vm.prank(caller);
        vm.expectRevert(Ownable.Unauthorized.selector);
        baseRegistrar.removeController(caller);
    }
}
