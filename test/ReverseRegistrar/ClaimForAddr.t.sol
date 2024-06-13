//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ReverseRegistrarBase} from "./ReverseRegistrarBase.t.sol";
import {ReverseRegistrar} from "src/L2/ReverseRegistrar.sol";
import {Sha3} from "src/lib/Sha3.sol";
import {ADDR_REVERSE_NODE} from "src/util/Constants.sol";
import {MockOwnedContract} from "test/mocks/MockOwnedContract.sol";

contract ClaimForAddr is ReverseRegistrarBase {
    address resolver = makeAddr("resolver");

    function test_reverts_ifNotAuthorized() public {
        address revRecordAddr = makeAddr("revRecord");
        vm.expectRevert(abi.encodeWithSelector(ReverseRegistrar.NotAuthorized.selector, revRecordAddr, user));
        vm.prank(user);
        reverse.claimForAddr(revRecordAddr, user, resolver);
    }

    function test_allowsUser_toClaimForAddr_forUserAddress() public {
        bytes32 labelHash = Sha3.hexAddress(user);
        bytes32 reverseNode = keccak256(abi.encodePacked(ADDR_REVERSE_NODE, labelHash));

        vm.expectEmit(address(reverse));
        emit ReverseRegistrar.ReverseClaimed(user, reverseNode);
        vm.prank(user);
        bytes32 returnedReverseNode = reverse.claimForAddr(user, user, resolver);
        assertTrue(reverseNode == returnedReverseNode);
        address retOwner = registry.owner(reverseNode);
        assertTrue(retOwner == user);
        address retResolver = registry.resolver(reverseNode);
        assertTrue(retResolver == resolver);
    }

    function test_allowsOperator_toClaimForAddr_forUserAddress() public {
        bytes32 labelHash = Sha3.hexAddress(user);
        bytes32 reverseNode = keccak256(abi.encodePacked(ADDR_REVERSE_NODE, labelHash));
        address operator = makeAddr("operator");
        vm.prank(user);
        registry.setApprovalForAll(operator, true);

        vm.expectEmit(address(reverse));
        emit ReverseRegistrar.ReverseClaimed(user, reverseNode);
        vm.prank(operator);
        bytes32 returnedReverseNode = reverse.claimForAddr(user, user, resolver);
        assertTrue(reverseNode == returnedReverseNode);
        address retOwner = registry.owner(reverseNode);
        assertTrue(retOwner == user);
        address retResolver = registry.resolver(reverseNode);
        assertTrue(retResolver == resolver);
    }

    function test_allowsOwnerOfContract_toClaimForAddr_forOwnedContractAddress() public {
        MockOwnedContract ownedContract = new MockOwnedContract(user);
        bytes32 labelHash = Sha3.hexAddress(address(ownedContract));
        bytes32 reverseNode = keccak256(abi.encodePacked(ADDR_REVERSE_NODE, labelHash));

        vm.expectEmit(address(reverse));
        emit ReverseRegistrar.ReverseClaimed(address(ownedContract), reverseNode);
        vm.prank(user);
        bytes32 returnedReverseNode = reverse.claimForAddr(address(ownedContract), user, resolver);
        assertTrue(reverseNode == returnedReverseNode);
        address retOwner = registry.owner(reverseNode);
        assertTrue(retOwner == user);
        address retResolver = registry.resolver(reverseNode);
        assertTrue(retResolver == resolver);
    }
}
