//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {NameResolver} from "ens-contracts/resolvers/profiles/NameResolver.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {ReverseRegistrarBase} from "./ReverseRegistrarBase.t.sol";
import {ReverseRegistrar} from "src/L2/ReverseRegistrar.sol";
import {Sha3} from "src/lib/Sha3.sol";
import {ADDR_REVERSE_NODE} from "src/util/Constants.sol";

contract ClaimForAddr is ReverseRegistrarBase {
    function test_reverts_ifNotAuthorized() public {
        address revRecordAddr = makeAddr("revRecord");
        vm.expectRevert(abi.encodeWithSelector(ReverseRegistrar.NotAuthorized.selector, revRecordAddr, user));
        vm.prank(user);
        reverse.claimForAddr(revRecordAddr, user, makeAddr("resolver"));
    }

    function test_allowsSelf_toClaim() public {
        bytes32 labelHash = Sha3.hexAddress(user);
        bytes32 reverseNode = keccak256(abi.encodePacked(ADDR_REVERSE_NODE, labelHash));

        vm.expectEmit();
        emit ReverseRegistrar.ReverseClaimed(user, reverseNode);
        vm.prank(user);
        bytes32 returnedReverseNode = reverse.claim(user);
        assertTrue(reverseNode == returnedReverseNode);
    }
}