// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import {Registry} from "src/L2/Registry.sol";
import {ENS} from "ens-contracts/registry/ENS.sol";
import {ETH_NODE, BASE_ETH_NODE} from "src/util/Constants.sol";
import {NameEncoder} from "ens-contracts/utils/NameEncoder.sol";
import {RegistryBase} from "./RegistryBase.t.sol";

contract SetRecord is RegistryBase {
    function test_setsTheRecordCorrectly() public {
        vm.expectEmit();
        emit ENS.Transfer(ETH_NODE, nodeOwner);
        vm.expectEmit();
        emit ENS.NewResolver(ETH_NODE, address(resolver));
        vm.expectEmit();
        emit ENS.NewTTL(ETH_NODE, TTL);
        vm.prank(ethOwner);
        registry.setRecord(ETH_NODE, nodeOwner, address(resolver), TTL);

        address storedOwner = registry.owner(ETH_NODE);
        address storedResolver = registry.resolver(ETH_NODE);
        uint64 storedTtl = registry.ttl(ETH_NODE);
        assertTrue(storedOwner == nodeOwner);
        assertTrue(storedResolver == address(resolver));
        assertTrue(storedTtl == TTL);
    }

    function test_reverts_whenTheCallerIsNotAuthroized(address caller) public {
        vm.assume(caller != ethOwner);
        vm.expectRevert(Registry.Unauthorized.selector);
        vm.prank(caller);
        registry.setRecord(ETH_NODE, nodeOwner, address(resolver), TTL);
    }
}
