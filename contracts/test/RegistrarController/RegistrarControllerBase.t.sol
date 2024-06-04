// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {RegistrarController} from "src/L2/RegistrarController.sol";
import {IPriceOracle} from "src/L2/interface/IPriceOracle.sol";
import {BaseRegistrar} from "src/L2/BaseRegistrar.sol";
import {Registry} from "src/L2/Registry.sol";
import {IReverseRegistrar} from "src/L2/interface/IReverseRegistrar.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ENS} from "ens-contracts/registry/ENS.sol";

import {MockBaseRegistrar} from "test/mocks/MockBaseRegistrar.sol";
import {MockReverseRegistrar} from "test/mocks/MockReverseRegistrar.sol";
import {MockUSDC} from "test/mocks/MockUSDC.sol";
import {MockNameWrapper} from "test/mocks/MockNameWrapper.sol";
import {MockPriceOracle} from "test/mocks/MockPriceOracle.sol";
import {MockDiscountValidator} from "test/mocks/MockDiscountValidator.sol";

import {REVERSE_NODE} from "src/util/Constants.sol";

import "forge-std/console.sol";

contract RegistrarControllerBase is Test {
    RegistrarController public controller;
    MockBaseRegistrar public base;
    MockReverseRegistrar public reverse;
    MockUSDC public usdc;
    MockPriceOracle public prices;
    Registry public registry;

    address owner = makeAddr("owner");
    address user = makeAddr("user");
    address resolver = makeAddr("resolver");

    string public name = "test";
    string public shortName = "t";
    bytes32 public nameLabel = keccak256(bytes(name));
    bytes32 public shortNameLabel = keccak256(bytes(shortName));

    MockDiscountValidator public validator;
    bytes32 public discountKey = keccak256(bytes("default.discount"));
    uint256 discountAmount = 0.1 ether;
    uint256 duration = 365 days;

    function setUp() public {
        base = new MockBaseRegistrar();
        reverse = new MockReverseRegistrar();
        usdc = new MockUSDC();
        prices = new MockPriceOracle();
        registry = new Registry(owner);
        validator = new MockDiscountValidator();
        _establishNamespace();

        vm.prank(owner);
        controller = new RegistrarController(
            BaseRegistrar(address(base)),
            IPriceOracle(address(prices)),
            IERC20(address(usdc)),
            IReverseRegistrar(address(reverse)),
            owner
        );
    }

    function test_controller_constructor() public view {
        assertEq(address(controller.prices()), address(prices));
        assertEq(address(controller.reverseRegistrar()), address(reverse));
        assertEq(address(controller.usdc()), address(usdc));
        assertTrue(reverse.hasClaimed());
        assertEq(controller.owner(), owner);
    }

    function _establishNamespace() internal virtual {}

    function _getDefaultDiscount() internal view returns (RegistrarController.DiscountDetails memory) {
        return  RegistrarController.DiscountDetails({
            active: true,
            discountValidator: address(validator),
            discount: discountAmount
        });
    }

    function _getDefaultRegisterRequest() internal virtual view returns (RegistrarController.RegisterRequest memory) {
        return RegistrarController.RegisterRequest({
            name: name, 
            owner: user,
            duration: duration,
            resolver: resolver, 
            data: _getDefaultRegisterData(),
            reverseRecord: false
        });
    }

    function _getDefaultRegisterData() internal virtual view returns (bytes[] memory data) {
        data = new bytes[](1);
        data[0] = bytes(name);
    }
}
