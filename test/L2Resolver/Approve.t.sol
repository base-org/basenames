// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {L2ResolverBase} from "./L2ResolverBase.t.sol";
import {L2Resolver} from "src/L2/L2Resolver.sol";

contract Approve is L2ResolverBase {
    function test_revertsIfCalledForSelf() public {
        vm.expectRevert(L2Resolver.CantSetSelfAsDelegate.selector);
        vm.prank(user);
        resolver.approve(node, user, true);
    }

    function test_allowsSenderToSetDelegate(address operator) public {
        vm.assume(operator != user);
        vm.expectEmit(address(resolver));
        emit L2Resolver.Approved(user, node, operator, true);
        vm.prank(user);
        resolver.approve(node, operator, true);
        assertTrue(resolver.isApprovedFor(user, node, operator));
    }
}
