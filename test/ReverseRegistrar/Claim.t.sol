//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ReverseRegistrarBase} from "./ReverseRegistrarBase.t.sol";
import {ReverseRegistrar} from "src/L2/ReverseRegistrar.sol";
import {Sha3} from "src/lib/Sha3.sol";
import {ADDR_REVERSE_NODE, BASE_REVERSE_NODE} from "src/util/Constants.sol";

contract Claim is ReverseRegistrarBase {
    address resolver = makeAddr("resolver");

    function test_allowsUser_toClaim() public {
        bytes32 labelHash = Sha3.hexAddress(user);
        bytes32 reverseNode = keccak256(abi.encodePacked(ADDR_REVERSE_NODE, labelHash));
        bytes32 baseReverseNode = keccak256(abi.encodePacked(BASE_REVERSE_NODE, labelHash));

        vm.prank(owner);
        reverse.setDefaultResolver(resolver);

        vm.expectEmit(address(reverse));
        emit ReverseRegistrar.BaseReverseClaimed(user, baseReverseNode);
        vm.expectEmit(address(reverse));
        emit ReverseRegistrar.ReverseClaimed(user, reverseNode);

        vm.prank(user);
        bytes32 returnedReverseNode = reverse.claim(user);

        assertTrue(reverseNode == returnedReverseNode);
        address retOwner = registry.owner(reverseNode);
        assertTrue(retOwner == user);
        address retBaseOwner = registry.owner(baseReverseNode);
        assertTrue(retBaseOwner == user);
        address retResolver = registry.resolver(reverseNode);
        assertTrue(retResolver == resolver);
        address retBaseResolver = registry.resolver(baseReverseNode);
        assertTrue(retBaseResolver == address(resolver));
    }
}
