// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import {Registry} from "src/L2/Registry.sol";
import {ENS} from "ens-contracts/registry/ENS.sol";
import {ETH_NODE, BASE_ETH_NODE} from "src/util/Constants.sol";
import {NameEncoder} from "ens-contracts/utils/NameEncoder.sol";
import {RegistryBase} from "./RegistryBase.t.sol";

contract SetOwner is RegistryBase {
    function test_setsOwnerCorrectly() public {
        vm.expectEmit();
        emit ENS.Transfer(ETH_NODE, nodeOwner);
        vm.prank(ethOwner);
        registry.setOwner(ETH_NODE, nodeOwner);

        address storedOwner = registry.owner(ETH_NODE);
        assertTrue(storedOwner == nodeOwner);
    }

    function test_reverts_whenTheCallerIsNotAuthroized(address caller) public {
        vm.assume(caller != ethOwner);
        vm.expectRevert(Registry.Unauthorized.selector);
        vm.prank(caller);
        registry.setOwner(ETH_NODE, nodeOwner);
    }
}
