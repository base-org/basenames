//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {BaseRegistrar} from "src/L2/BaseRegistrar.sol";
import {BaseRegistrarBase} from "./BaseRegistrarBase.t.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {ENS} from "ens-contracts/registry/ENS.sol";
import {BASE_ETH_NODE} from "src/util/Constants.sol";

contract SetResolver is BaseRegistrarBase {
    function test_allowsTheOwnerToSetTheResolver(address resolver) public {
        vm.expectEmit(address(registry));
        emit ENS.NewResolver(BASE_ETH_NODE, resolver);
        vm.prank(owner);
        baseRegistrar.setResolver(resolver);
        address returnedResolver = registry.resolver(BASE_ETH_NODE);
        assertTrue(returnedResolver == resolver);
    }

    function test_reverts_whenCalledByNonOwner(address caller) public {
        vm.assume(caller != owner);
        vm.prank(caller);
        vm.expectRevert(Ownable.Unauthorized.selector);
        baseRegistrar.setResolver(caller);
    }
}
