//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test, console} from "forge-std/Test.sol";
import "src/L2/StablePriceOracle.sol";
import "../mocks/MockOracle.sol";
import {StablePriceOracleTest} from "./Constructor.t.sol";

contract PriceTest is StablePriceOracleTest {
    function testPriceForDifferentNameLengths() public view {
        uint256 duration = 365 days;

        // test for 1 letter name
        IPriceOracle.Price memory price1 = stablePriceOracle.price("a", 0, duration);
        assertEq(price1.base_usdc, rent1 * duration);

        // test for 2 letter name 
        IPriceOracle.Price memory price2 = stablePriceOracle.price("ab", 0, duration);
        assertEq(price2.base_usdc, rent2 * duration);

        // test for 3 letter name
        IPriceOracle.Price memory price3 = stablePriceOracle.price("abc", 0, duration);
        assertEq(price3.base_usdc, rent3 * duration);
        assertEq(price3.premium_usdc, 0); 
        assertEq(price3.base_wei, (rent3 * duration * 1e8) / uint256(mockOracle.latestAnswer()));
        assertEq(price3.premium_wei, 0);

        // test for 4 letter name
        IPriceOracle.Price memory price4 = stablePriceOracle.price("abcd", 0, duration);
        assertEq(price4.base_usdc, rent4 * duration);

        // test for 5 letter name
        IPriceOracle.Price memory price5 = stablePriceOracle.price("abcde", 0, duration);
        assertEq(price5.base_usdc, rent5 * duration);

        // test for 5 or more letters
        IPriceOracle.Price memory price6 = stablePriceOracle.price("abcdef", 0, duration);
        assertEq(price6.base_usdc, rent5 * duration);
    }


    function testPremium() public view {
        uint256 premiumWei = stablePriceOracle.premium("abc", 0, 365 days);
        assertEq(premiumWei, 0);
    }

    function testAttoUSDToWei() public view {
        uint256 attoUSD = 3e13; // precise to ten decimal places
        uint256 expectedWei = 1e18;
        uint256 convertedWei = stablePriceOracle.attoUSDToWei(attoUSD);
        assertEq(convertedWei, expectedWei);
    }

}

