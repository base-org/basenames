//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {ReverseRegistrar} from "src/L2/ReverseRegistrar.sol";
import {Registry} from "src/L2/Registry.sol";
import {ENS} from "ens-contracts/registry/ENS.sol";
import {ETH_NODE, REVERSE_NODE, BASE_REVERSE_NODE} from "src/util/Constants.sol";

contract ReverseRegistrarBase is Test {
    address public owner = makeAddr("owner");
    address public user = makeAddr("user");
    address public controller = makeAddr("controller");

    Registry public registry;
    ReverseRegistrar public reverse;

    function setUp() public {
        registry = new Registry(owner);
        reverse = new ReverseRegistrar(ENS(address(registry)), owner, BASE_REVERSE_NODE);
        vm.prank(owner);
        reverse.setControllerApproval(controller, true);
        _registrySetup();
    }

    function _registrySetup() internal virtual {
        // establish the base.eth namespace
        bytes32 ethLabel = keccak256("eth");
        bytes32 baseLabel = keccak256("base");
        vm.prank(owner);
        registry.setSubnodeOwner(0x0, ethLabel, owner);
        vm.prank(owner);
        registry.setSubnodeOwner(ETH_NODE, baseLabel, owner);

        // establish the 80002105.reverse namespace
        vm.prank(owner);
        registry.setSubnodeOwner(0x0, keccak256("reverse"), owner);
        vm.prank(owner);
        registry.setSubnodeOwner(REVERSE_NODE, keccak256("80002105"), address(reverse));
    }

    function test_constructor() public view {
        assertTrue(reverse.owner() == owner);
        assertTrue(address(reverse.registry()) == address(registry));
        assertTrue(reverse.controllers(controller));
    }
}
