//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test, console} from "forge-std/Test.sol";
import "src/L2/StablePriceOracle.sol";
import "../mocks/MockOracle.sol";
import {StablePriceOracleTest} from "./ConstructorTest.t.sol";

contract PriceTest is StablePriceOracleTest {
    uint256 duration = 365 days;
    function test_price_calculatePrice_oneLetter() public view {
        IPriceOracle.Price memory price1 = stablePriceOracle.price("a", 0, duration);
        assertEq(price1.base_usdc, rent1 * duration);
    }

    function test_price_calculatesPrice_twoLetters() public view { 
        IPriceOracle.Price memory price2 = stablePriceOracle.price("ab", 0, duration);
        assertEq(price2.base_usdc, rent2 * duration);
    }

    function test_price_calculatesPrice_threeLetters() public view { 
        IPriceOracle.Price memory price3 = stablePriceOracle.price("abc", 0, duration);
        assertEq(price3.base_usdc, rent3 * duration);
        assertEq(price3.premium_usdc, 0); 
        assertEq(price3.base_wei, (rent3 * duration * 1e8) / uint256(mockOracle.latestAnswer()));
        assertEq(price3.premium_wei, 0);
    }

    function test_price_calculatesPrice_fourLetters() public view { 
        IPriceOracle.Price memory price4 = stablePriceOracle.price("abcd", 0, duration);
        assertEq(price4.base_usdc, rent4 * duration);
    }

    function test_price_calculatesPrice_fiveLetters() public view { 
        IPriceOracle.Price memory price5 = stablePriceOracle.price("abcde", 0, duration);
        assertEq(price5.base_usdc, rent5 * duration);
    }

    function test_price_calculatesPrice_fiveOrMoreLetters() public view { 
        IPriceOracle.Price memory price6 = stablePriceOracle.price("abcdef", 0, duration);
        assertEq(price6.base_usdc, rent5 * duration);
    }

    function test_premium() public view {
        uint256 premiumWei = stablePriceOracle.premium("abc", 0, 365 days);
        assertEq(premiumWei, 0);
    }

    function test_AttoUSDToWei() public view {
        uint256 attoUSD = 3e13; // precise to ten decimal places
        uint256 expectedWei = 1e18;
        uint256 convertedWei = stablePriceOracle.attoUSDToWei(attoUSD);
        assertEq(convertedWei, expectedWei);
    }

}

