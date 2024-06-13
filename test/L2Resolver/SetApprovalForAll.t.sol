// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {L2ResolverBase} from "./L2ResolverBase.t.sol";
import {L2Resolver} from "src/L2/L2Resolver.sol";

contract SetApprovalForAll is L2ResolverBase {
    function test_revertsIfCalledForSelf() public {
        vm.expectRevert(L2Resolver.CantSetSelfAsOperator.selector);
        vm.prank(user);
        resolver.setApprovalForAll(user, true);
    }

    function test_allowsSenderToSetApproval(address operator) public {
        vm.assume(operator != user);
        vm.expectEmit(address(resolver));
        emit L2Resolver.ApprovalForAll(user, operator, true);
        vm.prank(user);
        resolver.setApprovalForAll(operator, true);
        assertTrue(resolver.isApprovedForAll(user, operator));
    }
}
