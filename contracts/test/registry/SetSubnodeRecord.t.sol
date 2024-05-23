// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import {Registry} from "src/L2/Registry.sol";
import {ENS} from "ens-contracts/registry/ENS.sol";
import {ETH_NODE, BASE_ETH_NODE} from "src/util/Constants.sol";
import {NameEncoder} from "ens-contracts/utils/NameEncoder.sol";
import {RegistryBase} from "./RegistryBase.t.sol";

contract SetSubnodeRecord is RegistryBase {
    bytes32 label = keccak256("test");

    function test_setsTheSubnodeRecordCorrectly() public {
        bytes32 node = keccak256(abi.encodePacked(ETH_NODE, label)); // test.eth
        vm.expectEmit();
        emit ENS.NewOwner(ETH_NODE, label, nodeOwner);
        vm.expectEmit();
        emit ENS.NewResolver(node, address(resolver));
        vm.expectEmit();
        emit ENS.NewTTL(node, TTL);
        vm.prank(ethOwner);
        registry.setSubnodeRecord(ETH_NODE, label, nodeOwner, address(resolver), TTL);

        address storedOwner = registry.owner(node);
        address storedResolver = registry.resolver(node);
        uint64 storedTtl = registry.ttl(node);
        assertTrue(storedOwner == nodeOwner);
        assertTrue(storedResolver == address(resolver));
        assertTrue(storedTtl == TTL);
    }

    function test_reverts_whenTheCallerIsNotAuthroized(address caller) public {
        vm.assume(caller != ethOwner);
        vm.expectRevert(Registry.Unauthorized.selector);
        vm.prank(caller);
        registry.setSubnodeRecord(ETH_NODE, label, nodeOwner, address(resolver), TTL);
    }
}
