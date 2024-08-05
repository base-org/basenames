// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {L2Resolver} from "src/L2/L2Resolver.sol";
import {Registry} from "src/L2/Registry.sol";
import {ENS} from "ens-contracts/registry/ENS.sol";
import {ETH_NODE, REVERSE_NODE} from "src/util/Constants.sol";
import {NameEncoder} from "ens-contracts/utils/NameEncoder.sol";
import {MockReverseRegistrar} from "test/mocks/MockReverseRegistrar.sol";

contract L2ResolverBase is Test {
    L2Resolver public resolver;
    Registry public registry;
    address reverse;
    address controller = makeAddr("controller");
    address owner = makeAddr("owner");
    address user = makeAddr("user");
    string name = "test.base.eth";
    bytes32 label = keccak256("test");
    bytes32 node;

    function setUp() public {
        registry = new Registry(owner);
        reverse = address(new MockReverseRegistrar());
        resolver = new L2Resolver(ENS(address(registry)), controller, reverse, owner);
        (, node) = NameEncoder.dnsEncodeName(name);
        _establishNamespace();
    }

    function test_constructor() public view {
        assertEq(address(resolver.ens()), address(registry));
        assertEq(resolver.registrarController(), controller);
        assertEq(resolver.reverseRegistrar(), reverse);
        assertEq(resolver.owner(), owner);
    }

    function _establishNamespace() internal virtual {
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
}
