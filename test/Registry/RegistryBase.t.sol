// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {Registry} from "src/L2/Registry.sol";
import {ETH_NODE} from "src/util/Constants.sol";

import {MockPublicResolver} from "../mocks/MockPublicResolver.sol";

contract RegistryBase is Test {
    uint64 TTL = type(uint64).max;
    Registry public registry;
    MockPublicResolver public resolver;

    address public rootOwner = makeAddr("0x1");
    address public ethOwner = makeAddr("eth");
    address public baseEthOwner = makeAddr("base");
    address public nodeOwner = makeAddr("test");

    function setUp() public {
        registry = new Registry(rootOwner);
        resolver = new MockPublicResolver();
        registry.owner(0x0);
        _ownershipSetup();
    }

    function test_constructor_setsTheRootNodeOwner() public view {
        assertTrue(registry.owner(bytes32(0)) == rootOwner);
    }

    function _ownershipSetup() internal virtual {
        // establish the base.eth namespace
        bytes32 ethLabel = keccak256("eth");
        bytes32 baseLabel = keccak256("base");
        vm.prank(rootOwner);
        registry.setSubnodeOwner(0x0, ethLabel, ethOwner);
        vm.prank(ethOwner);
        registry.setSubnodeOwner(ETH_NODE, baseLabel, baseEthOwner);
    }
}
