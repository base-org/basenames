// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import {Registry} from "src/L2/Registry.sol";
import {ENS} from "ens-contracts/registry/ENS.sol";
import {ETH_NODE, BASE_ETH_NODE} from "src/util/Constants.sol";
import {NameEncoder} from "ens-contracts/utils/NameEncoder.sol";
import {RegistryBase} from "./RegistryBase.t.sol";

contract SetSubnodeOwner is RegistryBase {
    bytes32 label = keccak256("test");

    function test_setsSubnodeOwnerCorrectly() public {
        bytes32 node = keccak256(abi.encodePacked(ETH_NODE, label)); // test.eth
        vm.expectEmit();
        emit ENS.NewOwner(ETH_NODE, label, nodeOwner);
        vm.prank(ethOwner);
        registry.setSubnodeOwner(ETH_NODE, label, nodeOwner);

        address storedOwner = registry.owner(node);
        assertTrue(storedOwner == nodeOwner);
    }

    function test_reverts_whenTheCallerIsNotAuthroized(address caller) public {
        vm.assume(caller != ethOwner);
        vm.expectRevert(Registry.Unauthorized.selector);
        vm.prank(caller);
        registry.setSubnodeOwner(ETH_NODE, label, nodeOwner);
    }
}
