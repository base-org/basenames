// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {L2ResolverBase} from "./L2ResolverBase.t.sol";
import {L2Resolver} from "src/L2/L2Resolver.sol";
import {BASE_ETH_NODE} from "src/util/Constants.sol";

// Because isAuthorized() is an internal method, we test it indirectly here by using `setAddr()` which
// checks the authorization status via `isAuthorized()`.
contract IsAuthorised is L2ResolverBase {
    function test_returnsTrue_ifSenderIsController() public {
        vm.prank(controller);
        resolver.setAddr(node, user);
        assertEq(resolver.addr(node), user);
    }

    function test_returnsTrue_ifSenderIsReverse() public {
        vm.prank(reverse);
        resolver.setAddr(node, user);
        assertEq(resolver.addr(node), user);
    }

    function test_returnsTrue_ifSenderIOwnerOfNode() public {
        vm.prank(owner);
        registry.setSubnodeOwner(BASE_ETH_NODE, label, user);
        vm.prank(user);
        resolver.setAddr(node, user);
        assertEq(resolver.addr(node), user);
    }

    function test_returnsTrue_ifSenderIOperatorOfNode(address operator) public {
        vm.assume(operator != owner && operator != user && operator != address(0));
        vm.prank(owner);
        registry.setSubnodeOwner(BASE_ETH_NODE, label, user);
        vm.prank(user);
        resolver.setApprovalForAll(operator, true);
        vm.prank(operator);
        resolver.setAddr(node, user);
        assertEq(resolver.addr(node), user);
    }

    function test_returnsTrue_ifSenderIDelegateOfNode(address operator) public {
        vm.assume(operator != owner && operator != user && operator != address(0));
        vm.prank(owner);
        registry.setSubnodeOwner(BASE_ETH_NODE, label, user);
        vm.prank(user);
        resolver.approve(node, operator, true);
        vm.prank(operator);
        resolver.setAddr(node, user);
        assertEq(resolver.addr(node), user);
    }
}
