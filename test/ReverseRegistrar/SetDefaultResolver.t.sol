//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {NameResolver} from "ens-contracts/resolvers/profiles/NameResolver.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {ReverseRegistrarBase} from "./ReverseRegistrarBase.t.sol";
import {ReverseRegistrar} from "src/L2/ReverseRegistrar.sol";

contract SetDefaultResolver is ReverseRegistrarBase {
    function test_reverts_whenCalledByNonOwner(address caller) public {
        vm.assume(caller != owner);
        vm.expectRevert(Ownable.Unauthorized.selector);
        vm.prank(caller);
        reverse.setDefaultResolver(makeAddr("fake"));
    }

    function test_reverts_whenPassedZeroAddress() public {
        vm.expectRevert(ReverseRegistrar.NoZeroAddress.selector);
        vm.prank(owner);
        reverse.setDefaultResolver(address(0));
    }

    function test_setsTheDefaultResolver() public {
        address resolverAddr = makeAddr("resolver");
        vm.expectEmit(address(reverse));
        emit ReverseRegistrar.DefaultResolverChanged(NameResolver(resolverAddr));
        vm.prank(owner);
        reverse.setDefaultResolver(resolverAddr);
        assertTrue(reverse.defaultResolver() == NameResolver(resolverAddr));
    }
}
