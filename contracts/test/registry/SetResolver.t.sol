// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import {Registry} from "src/L2/Registry.sol";
import {ENS} from "ens-contracts/registry/ENS.sol";
import {ETH_NODE, BASE_ETH_NODE} from "src/util/Constants.sol";
import {NameEncoder} from "ens-contracts/utils/NameEncoder.sol";
import {RegistryBase} from "./RegistryBase.t.sol";

contract SetResolver is RegistryBase {
    function test_setsTheResolverCorrectly() public {
        vm.expectEmit();
        emit ENS.NewResolver(ETH_NODE, address(resolver));
        vm.prank(ethOwner);
        registry.setResolver(ETH_NODE, address(resolver));

        address storedResolver = registry.resolver(ETH_NODE);
        assertTrue(storedResolver == address(resolver));
    }

    function test_reverts_whenTheCallerIsNotAuthroized(address caller) public {
        vm.assume(caller != ethOwner);
        vm.expectRevert(Registry.Unauthorized.selector);
        vm.prank(caller);
        registry.setResolver(ETH_NODE, address(resolver));
    }
}
