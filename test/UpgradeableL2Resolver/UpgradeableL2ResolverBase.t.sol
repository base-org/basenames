// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {UpgradeableL2Resolver} from "src/L2/UpgradeableL2Resolver.sol";
import {TransparentUpgradeableProxy} from
    "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Registry} from "src/L2/Registry.sol";
import {ENS} from "ens-contracts/registry/ENS.sol";
import {ETH_NODE, REVERSE_NODE} from "src/util/Constants.sol";
import {NameEncoder} from "ens-contracts/utils/NameEncoder.sol";
import {MockReverseRegistrar} from "test/mocks/MockReverseRegistrar.sol";

contract UpgradeableL2ResolverBase is Test {
    UpgradeableL2Resolver public resolverImpl;
    TransparentUpgradeableProxy public proxy;
    UpgradeableL2Resolver public resolver;
    Registry public registry;
    address reverse;
    address controller = makeAddr("controller");
    address admin = makeAddr("admin");
    address owner = makeAddr("owner");
    address user = makeAddr("user");
    string name = "test.base.eth";
    bytes32 label = keccak256("test");
    bytes32 node;

    function setUp() public {
        registry = new Registry(owner);
        reverse = address(new MockReverseRegistrar());
        resolverImpl = new UpgradeableL2Resolver();
        proxy = new TransparentUpgradeableProxy(
            address(resolverImpl),
            admin,
            abi.encodeWithSelector(
                UpgradeableL2Resolver.initialize.selector, registry, address(controller), address(reverse), owner
            )
        );
        resolver = UpgradeableL2Resolver(address(proxy));
        (, node) = NameEncoder.dnsEncodeName(name);
        _establishNamespace();
    }

    function _establishNamespace() internal virtual {
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
}
