//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {BaseRegistrar} from "src/L2/BaseRegistrar.sol";
import {MockPublicResolver} from "test/mocks/MockPublicResolver.sol";
import {Registry} from "src/L2/Registry.sol";
import {ETH_NODE, BASE_ETH_NODE} from "src/util/Constants.sol";

contract BaseRegistrarBase is Test {
    Registry public registry;
    BaseRegistrar public baseRegistrar;
    address public owner = makeAddr("owner");
    address public user = makeAddr("user");
    address public controller = makeAddr("controller");
    address public resolver = makeAddr("resolver");
    uint64 public ttl = 0;
    bytes32 public label = keccak256("test");
    uint256 public id = uint256(label);
    bytes32 public node = keccak256(abi.encodePacked(BASE_ETH_NODE, label));
    uint256 public duration = 365 days;
    uint256 public blockTimestamp = 1716496498; // May 23, 2024
    string public baseURI = "https://base.org/api/basenames/metadata/";
    string public collectionURI = "https://base.org/api/basenames/contract/";

    function setUp() public {
        vm.prank(owner);
        registry = new Registry(owner);
        baseRegistrar = new BaseRegistrar(registry, owner, BASE_ETH_NODE, baseURI, collectionURI);
        _ensSetup();
    }

    function test_constructor() public view {
        assertEq(baseRegistrar.owner(), owner);
        assertEq(address(baseRegistrar.registry()), address(registry));
        assertEq(baseRegistrar.baseNode(), BASE_ETH_NODE);
    }

    function _ensSetup() public virtual {
        // establish the base.eth namespace and set the baseRegistrar as the owner of "base.eth"
        bytes32 ethLabel = keccak256("eth");
        bytes32 baseLabel = keccak256("base");
        vm.prank(owner);
        registry.setSubnodeOwner(0x0, ethLabel, owner);
        vm.prank(owner);
        registry.setSubnodeOwner(ETH_NODE, baseLabel, address(baseRegistrar));
    }

    function _registrationSetup() internal virtual {
        vm.prank(owner);
        baseRegistrar.addController(controller);
    }

    function _registerName(bytes32 label_, address nameOwner, uint256 duration_) internal virtual returns (uint256) {
        vm.warp(blockTimestamp);
        vm.prank(controller);
        return baseRegistrar.register(uint256(label_), nameOwner, duration_);
    }
}
