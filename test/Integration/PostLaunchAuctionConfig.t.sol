//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {IntegrationTestBase} from "./IntegrationTestBase.t.sol";
import {RegistrarController} from "src/L2/RegistrarController.sol";
import {ExponentialPremiumPriceOracle} from "src/L2/ExponentialPremiumPriceOracle.sol";
import {GRACE_PERIOD} from "src/util/Constants.sol";
import {IPriceOracle} from "src/L2/interface/IPriceOracle.sol";

contract PostLaunchAuctionConfig is IntegrationTestBase {
    string name = "alice";
    uint256 duration = 365.25 days;
    uint256 id = uint256(keccak256(bytes(name)));

    function test_simulatePostAuctionConfig_register() public {
        // Deploy original price oracle, we will do this ahead of launch
        exponentialPremiumPriceOracle = new ExponentialPremiumPriceOracle(
            _getBasePrices(), EXPIRY_AUCTION_START_PRICE, EXPIRY_AUCTION_DURATION_DAYS
        );

        // Jump forward 30 days
        vm.warp(LAUNCH_TIME + 30 days);

        // Get price before oracle changes
        uint256 priceBeforeSwitch = registrarController.registerPrice(name, duration);

        // Set new price oracle on registrar controller (ownerOnly method)
        vm.prank(owner);
        registrarController.setPriceOracle(IPriceOracle(exponentialPremiumPriceOracle));

        //// Register a name and check price + success
        uint256 price = registrarController.registerPrice(name, duration);
        vm.deal(alice, price);

        assertEq(priceBeforeSwitch, price);

        RegistrarController.RegisterRequest memory request = RegistrarController.RegisterRequest({
            name: name,
            owner: alice,
            duration: duration,
            resolver: address(defaultL2Resolver),
            data: new bytes[](0),
            reverseRecord: true
        });

        vm.expectEmit(address(registrarController));
        emit RegistrarController.ETHPaymentProcessed(alice, price);

        vm.prank(alice);
        registrarController.register{value: price}(request);
        assertEq(baseRegistrar.ownerOf(id), alice);

        uint256 expectedPrice = exponentialPremiumPriceOracle.price5Letter() * duration;
        assertEq(price, expectedPrice);

        console.log("______________________________");
        console.log("Timestamp: ", block.timestamp);
        console.log("Price (WEI): ", price);
        console.log("______________________________");
    }

    function test_simulateContingency() public {
        // Deploy original price oracle, we will do this ahead of launch
        exponentialPremiumPriceOracle = new ExponentialPremiumPriceOracle(
            _getBasePrices(), EXPIRY_AUCTION_START_PRICE, EXPIRY_AUCTION_DURATION_DAYS
        );

        // Jump forward 1 day
        vm.warp(LAUNCH_TIME + 1 days);

        // Set the launch time to 0 (eliminates launch premium auction, see: RegistrarController.sol:_getExpiry(id))
        vm.prank(owner);
        registrarController.setLaunchTime(0);
        // Set new price oracle on registrar controller (ownerOnly method)
        vm.prank(owner);
        registrarController.setPriceOracle(IPriceOracle(exponentialPremiumPriceOracle));

        //// Register a name and check price + success
        uint256 price = registrarController.registerPrice(name, duration);
        vm.deal(alice, price);

        RegistrarController.RegisterRequest memory request = RegistrarController.RegisterRequest({
            name: name,
            owner: alice,
            duration: duration,
            resolver: address(defaultL2Resolver),
            data: new bytes[](0),
            reverseRecord: true
        });

        vm.expectEmit(address(registrarController));
        emit RegistrarController.ETHPaymentProcessed(alice, price);

        vm.prank(alice);
        registrarController.register{value: price}(request);
        assertEq(baseRegistrar.ownerOf(id), alice);

        uint256 expectedPrice = exponentialPremiumPriceOracle.price5Letter() * duration;
        assertEq(price, expectedPrice);

        console.log("______________________________");
        console.log("Timestamp: ", block.timestamp);
        console.log("Price (WEI): ", price);
        console.log("______________________________");
    }

    function test_showAuctionPriceDifferences() public {
        // Jump forward 30 days
        vm.warp(LAUNCH_TIME + 30 days);

        //// Register a name
        uint256 price = registrarController.registerPrice(name, duration);
        vm.deal(alice, price);
        RegistrarController.RegisterRequest memory request = RegistrarController.RegisterRequest({
            name: name,
            owner: alice,
            duration: duration,
            resolver: address(defaultL2Resolver),
            data: new bytes[](0),
            reverseRecord: true
        });
        vm.prank(alice);
        registrarController.register{value: price}(request);

        // Jump ahead to expiry
        vm.warp(block.timestamp + duration + GRACE_PERIOD);

        uint256 priceWithLaunchAuction = registrarController.registerPrice(name, duration);
        // Deploy original price oracle and set as price oracle
        exponentialPremiumPriceOracle = new ExponentialPremiumPriceOracle(
            _getBasePrices(), EXPIRY_AUCTION_START_PRICE, EXPIRY_AUCTION_DURATION_DAYS
        );
        vm.prank(owner);
        registrarController.setPriceOracle(IPriceOracle(exponentialPremiumPriceOracle));
        uint256 priceWithProdAuction = registrarController.registerPrice(name, duration);

        console.log("Price with launch auction: ", priceWithLaunchAuction);
        console.log("Price with prod auction: ", priceWithProdAuction);
    }
}
