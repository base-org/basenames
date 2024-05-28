//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test, console} from "forge-std/Test.sol";
import "src/L2/StablePriceOracle.sol";
import "../mocks/MockOracle.sol";

contract PriceTest is Test {
    StablePriceOracle stablePriceOracle;
    MockOracle mockOracle;

    function setUp() public {
        mockOracle = new MockOracle(3000);
        uint256[] memory rentPrices = new uint256[](5);

        rentPrices[0] = 1000000;
        rentPrices[1] = 2000000;
        rentPrices[2] = 3000000;
        rentPrices[3] = 4000000;
        rentPrices[4] = 5000000;

        stablePriceOracle = new StablePriceOracle(mockOracle, rentPrices);
    }

    function testPriceForDifferentNameLengths() public view { // ensure all switch statements are hit
        uint256 duration = 365 days;

        // test for 1 letter name
        IPriceOracle.Price memory price1 = stablePriceOracle.price("a", 0, duration);
        assertEq(price1.base_usdc, 1000000 * duration);

        // test for 2 letter name 
        IPriceOracle.Price memory price2 = stablePriceOracle.price("ab", 0, duration);
        assertEq(price2.base_usdc, 2000000 * duration);

        // test for 3 letter name
        IPriceOracle.Price memory price3 = stablePriceOracle.price("abc", 0, duration);
        assertEq(price3.base_usdc, 3000000 * duration);

        // test for 4 letter name
        IPriceOracle.Price memory price4 = stablePriceOracle.price("abcd", 0, duration);
        assertEq(price4.base_usdc, 4000000 * duration);

        // test for 5 letter name
        IPriceOracle.Price memory price5 = stablePriceOracle.price("abcde", 0, duration);
        assertEq(price5.base_usdc, 5000000 * duration);

        // test for 5 or more letters
        IPriceOracle.Price memory price6 = stablePriceOracle.price("abcdef", 0, duration);
        assertEq(price6.base_usdc, 5000000 * duration);
    }

    function testPremium() public view {
        uint256 premiumWei = stablePriceOracle.premium("abc", 0, 365 days);
        assertEq(premiumWei, 0);
    }

    function testAttoUSDToWei() public view {
        uint256 attoUSD = 30000000000000; // precise to ten decimal places
        uint256 expectedWei = 1e18;
        uint256 convertedWei = stablePriceOracle.attoUSDToWei(attoUSD);
        console.log("converted Wei", convertedWei);
        assertEq(convertedWei, expectedWei);
    }

}

