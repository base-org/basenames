//SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {ReverseRegistrar} from "src/L2/ReverseRegistrar.sol";
import {Registry} from "src/L2/Registry.sol";
import {ENS} from "ens-contracts/registry/ENS.sol";
import {ETH_NODE, REVERSE_NODE, ADDR_REVERSE_NODE} from "src/util/Constants.sol";

contract ReverseRegistrarBase is Test {
    address public owner = makeAddr("0x1");
    address public user = makeAddr("0x2");

    Registry public registry;
    ReverseRegistrar public reverse;

    function setUp() public {
        registry = new Registry(owner);
        reverse = new ReverseRegistrar(ENS(address(registry)), owner);
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
        
        // establish the addr.reverse namespace 
        vm.prank(owner);
        registry.setSubnodeOwner(0x0, keccak256("reverse"), owner);
        vm.prank(owner);
        registry.setSubnodeOwner(REVERSE_NODE, keccak256("addr"), address(reverse));
    }

    function test_constructor() public view {
        assertTrue(registry.owner(ADDR_REVERSE_NODE) == address(reverse));
    }
}
