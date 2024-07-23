//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ReverseRegistrarBase} from "./ReverseRegistrarBase.t.sol";
import {Sha3} from "src/lib/Sha3.sol";
import {BASE_REVERSE_NODE} from "src/util/Constants.sol";

contract Node is ReverseRegistrarBase {
    function test_returnsExpectedNode(address addr) public view {
        bytes32 labelHash = Sha3.hexAddress(addr);
        bytes32 expectedNode = keccak256(abi.encodePacked(BASE_REVERSE_NODE, labelHash));
        bytes32 retNode = reverse.node(addr);
        assertTrue(retNode == expectedNode);
    }
}
