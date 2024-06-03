// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {RegistrarController} from "src/L2/RegistrarController.sol";
import {IPriceOracle} from "src/L2/interface/IPriceOracle.sol";
import {BaseRegistrar} from "src/L2/BaseRegistrar.sol";
import {Registry} from "src/L2/Registry.sol";
import {ReverseRegistrar} from "src/L2/ReverseRegistrar.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {INameWrapper} from "ens-contracts/wrapper/INameWrapper.sol";
import {ENS} from "ens-contracts/registry/ENS.sol";

import {MockBaseRegistrar} from "test/mocks/MockBaseRegistrar.sol";
import {MockReverseRegistrar} from "test/mocks/MockReverseRegistrar.sol";
import {MockUSDC} from "test/mocks/MockUSDC.sol";
import {MockNameWrapper} from "test/mocks/MockNameWrapper.sol";
import {MockPriceOracle} from "test/mocks/MockPriceOracle.sol";

import {REVERSE_NODE} from "src/util/Constants.sol";


contract RegistrarControllerBase is Test {
    
    RegistrarController public controller; 
    MockBaseRegistrar public base;
    MockReverseRegistrar public reverse;
    MockUSDC public usdc;
    MockNameWrapper public wrapper;
    MockPriceOracle public prices;
    Registry public registry;

    address owner = makeAddr("0x1");
    address user = makeAddr("0x2");

    function setUp() public {
        base = new MockBaseRegistrar();
        reverse = new MockReverseRegistrar();
        usdc = new MockUSDC();
        wrapper = new MockNameWrapper();
        prices = new MockPriceOracle();
        registry = new Registry(owner);
        bytes32 reverseLabel = keccak256("reverse");
        vm.prank(owner);
        registry.setSubnodeOwner(0x0, reverseLabel, owner);
        bytes32 addrLabel = keccak256("addr");
        vm.prank(owner);
        registry.setSubnodeOwner(REVERSE_NODE, addrLabel, address(reverse));

        controller = new RegistrarController(
            BaseRegistrar(address(base)),
            IPriceOracle(address(prices)),
            IERC20(address(usdc)),
            ReverseRegistrar(address(reverse)),
            INameWrapper(address(wrapper)),
            ENS(address(registry))
        );
    }

    function test_constructor() public view {
        assertTrue(address(controller.prices()) == address(prices));
        assertTrue(address(controller.reverseRegistrar()) == address(reverse));
        assertTrue(address(controller.nameWrapper()) == address(wrapper));
        assertTrue(address(controller.usdc()) == address(usdc));
        assertTrue(reverse.hasClaimed());
    }
}