// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {L2ResolverBase} from "./L2ResolverBase.t.sol";
import {L2Resolver} from "src/L2/L2Resolver.sol";
import {Ownable} from "solady/auth/Ownable.sol";

contract SetRegistrarController is L2ResolverBase {
    function test_reverts_ifCalledByNonOwner(address caller, address newController) public {
        vm.assume(caller != owner);
        vm.expectRevert(Ownable.Unauthorized.selector);
        vm.prank(caller);
        resolver.setRegistrarController(newController);
    }

    function test_setsTheRegistrarControllerAccordingly(address newController) public {
        vm.expectEmit();
        emit L2Resolver.RegistrarControllerUpdated(newController);
        vm.prank(owner);
        resolver.setRegistrarController(newController);
        assertEq(resolver.registrarController(), newController);
    }
}
