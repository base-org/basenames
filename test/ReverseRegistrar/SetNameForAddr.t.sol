//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ReverseRegistrarBase} from "./ReverseRegistrarBase.t.sol";
import {ReverseRegistrar} from "src/L2/ReverseRegistrar.sol";
import {Sha3} from "src/lib/Sha3.sol";
import {ADDR_REVERSE_NODE, BASE_REVERSE_NODE} from "src/util/Constants.sol";
import {NameResolver, MockNameResolver} from "test/mocks/MockNameResolver.sol";
import {MockOwnedContract} from "test/mocks/MockOwnedContract.sol";

contract SetNameForAddr is ReverseRegistrarBase {
    NameResolver resolver = new MockNameResolver();
    string name = "name";

    function test_allowsUser_toSetName_forUserAddress() public {
        bytes32 labelHash = Sha3.hexAddress(user);
        bytes32 reverseNode = keccak256(abi.encodePacked(ADDR_REVERSE_NODE, labelHash));
        bytes32 baseReverseNode = keccak256(abi.encodePacked(BASE_REVERSE_NODE, labelHash));

        vm.prank(owner);
        reverse.setDefaultResolver(address(resolver));

        vm.expectEmit(address(reverse));
        emit ReverseRegistrar.ReverseClaimed(user, reverseNode);
        vm.expectEmit(address(reverse));
        emit ReverseRegistrar.BaseReverseClaimed(user, baseReverseNode);
        vm.prank(user);
        bytes32 returnedReverseNode = reverse.setNameForAddr(user, user, address(resolver), name);

        assertTrue(reverseNode == returnedReverseNode);
        address retOwner = registry.owner(reverseNode);
        assertTrue(retOwner == user);
        address retBaseOwner = registry.owner(baseReverseNode);
        assertTrue(retBaseOwner == user);
        address retResolver = registry.resolver(reverseNode);
        assertTrue(retResolver == address(resolver));
        address retBaseResolver = registry.resolver(baseReverseNode);
        assertTrue(retBaseResolver == address(resolver));
        assertTrue(keccak256(abi.encode(resolver.name(reverseNode))) == keccak256(abi.encode(name)));
        assertTrue(keccak256(abi.encode(resolver.name(baseReverseNode))) == keccak256(abi.encode(name)));
    }

    function test_allowsOperator_toSetName_forUserAddress() public {
        bytes32 labelHash = Sha3.hexAddress(user);
        bytes32 reverseNode = keccak256(abi.encodePacked(ADDR_REVERSE_NODE, labelHash));
        bytes32 baseReverseNode = keccak256(abi.encodePacked(BASE_REVERSE_NODE, labelHash));

        address operator = makeAddr("operator");
        vm.prank(user);
        registry.setApprovalForAll(operator, true);

        vm.prank(owner);
        reverse.setDefaultResolver(address(resolver));

        vm.expectEmit(address(reverse));
        emit ReverseRegistrar.ReverseClaimed(user, reverseNode);
        vm.expectEmit(address(reverse));
        emit ReverseRegistrar.BaseReverseClaimed(user, baseReverseNode);
        vm.prank(operator);
        bytes32 returnedReverseNode = reverse.setNameForAddr(user, user, address(resolver), name);

        assertTrue(reverseNode == returnedReverseNode);
        address retOwner = registry.owner(reverseNode);
        assertTrue(retOwner == user);
        address retBaseOwner = registry.owner(baseReverseNode);
        assertTrue(retBaseOwner == user);
        address retResolver = registry.resolver(reverseNode);
        assertTrue(retResolver == address(resolver));
        address retBaseResolver = registry.resolver(baseReverseNode);
        assertTrue(retBaseResolver == address(resolver));
        assertTrue(keccak256(abi.encode(resolver.name(reverseNode))) == keccak256(abi.encode(name)));
        assertTrue(keccak256(abi.encode(resolver.name(baseReverseNode))) == keccak256(abi.encode(name)));
    }

    function test_allowsOwnerOfContract_toSetName_forOwnedContractAddress() public {
        MockOwnedContract ownedContract = new MockOwnedContract(user);
        bytes32 labelHash = Sha3.hexAddress(address(ownedContract));
        bytes32 reverseNode = keccak256(abi.encodePacked(ADDR_REVERSE_NODE, labelHash));
        bytes32 baseReverseNode = keccak256(abi.encodePacked(BASE_REVERSE_NODE, labelHash));

        vm.expectEmit(address(reverse));
        emit ReverseRegistrar.ReverseClaimed(address(ownedContract), reverseNode);
        vm.expectEmit(address(reverse));
        emit ReverseRegistrar.BaseReverseClaimed(address(ownedContract), baseReverseNode);
        vm.prank(user);
        bytes32 returnedReverseNode = reverse.setNameForAddr(address(ownedContract), user, address(resolver), name);

        assertTrue(reverseNode == returnedReverseNode);
        address retOwner = registry.owner(reverseNode);
        assertTrue(retOwner == user);
        address retBaseOwner = registry.owner(baseReverseNode);
        assertTrue(retBaseOwner == user);
        address retResolver = registry.resolver(reverseNode);
        assertTrue(retResolver == address(resolver));
        address retBaseResolver = registry.resolver(baseReverseNode);
        assertTrue(retBaseResolver == address(resolver));
        assertTrue(keccak256(abi.encode(resolver.name(reverseNode))) == keccak256(abi.encode(name)));
        assertTrue(keccak256(abi.encode(resolver.name(baseReverseNode))) == keccak256(abi.encode(name)));
    }
}
