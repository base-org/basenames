// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import {Registry} from "src/L2/Registry.sol";
import {ENS} from "ens-contracts/registry/ENS.sol";
import {ETH_NODE, BASE_ETH_NODE} from "src/util/Constants.sol";
import {NameEncoder} from "ens-contracts/utils/NameEncoder.sol";
import {RegistryBase} from "./RegistryBase.t.sol";

contract SetResolver is RegistryBase {
    function test_setsApprovalCorrectly() public {
        vm.expectEmit();
        emit ENS.ApprovalForAll(ethOwner, nodeOwner, true);
        vm.prank(ethOwner);
        registry.setApprovalForAll(nodeOwner, true);

        vm.prank(nodeOwner);
        address newResolver = makeAddr("resolver");
        registry.setResolver(ETH_NODE, newResolver);
        address storedResolver = registry.resolver(ETH_NODE);
        assertTrue(storedResolver == newResolver);
        assertTrue(registry.isApprovedForAll(ethOwner, nodeOwner));
    }

    function test_revokesApprovalCorrectly() public {
        vm.prank(ethOwner);
        registry.setApprovalForAll(nodeOwner, true);
        assertTrue(registry.isApprovedForAll(ethOwner, nodeOwner));
        vm.prank(nodeOwner);
        address newResolver = makeAddr("resolver");
        registry.setResolver(ETH_NODE, newResolver);
        address storedResolver = registry.resolver(ETH_NODE);
        assertTrue(storedResolver == newResolver);

        vm.expectEmit();
        emit ENS.ApprovalForAll(ethOwner, nodeOwner, false);
        vm.prank(ethOwner);
        registry.setApprovalForAll(nodeOwner, false);
        assertFalse(registry.isApprovedForAll(ethOwner, nodeOwner));

        vm.prank(nodeOwner);
        vm.expectRevert(Registry.Unauthorized.selector);
        address newerResolver = makeAddr("resolver2");
        registry.setResolver(ETH_NODE, newerResolver);
    }
}
