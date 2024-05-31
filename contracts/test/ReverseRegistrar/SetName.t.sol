//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ReverseRegistrarBase} from "./ReverseRegistrarBase.t.sol";
import {ReverseRegistrar} from "src/L2/ReverseRegistrar.sol";
import {Sha3} from "src/lib/Sha3.sol";
import {ADDR_REVERSE_NODE} from "src/util/Constants.sol";
import {NameResolver, MockNameResolver} from "test/mocks/MockNameResolver.sol";

contract SetName is ReverseRegistrarBase {
    NameResolver resolver = new MockNameResolver();

    function test_setsName() public {
        bytes32 labelHash = Sha3.hexAddress(user);
        bytes32 reverseNode = keccak256(abi.encodePacked(ADDR_REVERSE_NODE, labelHash));

        string memory name = "name";
        vm.prank(owner);
        reverse.setDefaultResolver(address(resolver));

        vm.expectEmit();
        emit ReverseRegistrar.ReverseClaimed(user, reverseNode);
        vm.prank(user);
        bytes32 returnedReverseNode = reverse.setName(name);
        assertTrue(reverseNode == returnedReverseNode);
        address retOwner = registry.owner(reverseNode);
        assertTrue(retOwner == user);
        address retResolver = registry.resolver(reverseNode);
        assertTrue(retResolver == address(resolver));
        assertTrue(keccak256(abi.encode(resolver.name(reverseNode))) == keccak256(abi.encode(name)));
    }
}