//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test, console} from "forge-std/Test.sol";
import {StablePriceOracle} from "src/L2/StablePriceOracle.sol";
import {IPriceOracle} from "src/L2/interface/IPriceOracle.sol";
import {MockOracle} from "../mocks/MockOracle.sol";
import {StablePriceOracleBase} from "./ConstructorTest.t.sol";

contract Price is StablePriceOracleBase {
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
    function test_price_reverts_unicodeCharacters() public { // Test case for the failed fuzz test to determine which field is causing the error
    
        string memory name = unicode"𐏔Ⱥs%𝔵b.ハ|\"*༸&`"; // Erroring on input with Unicode characters

        uint256 expires = 32987790711288265998887799860420900946; // expires value in the counterexample 

        uint256 duration = 120886407775381395340616426642328538404563530755442021068989041128827069110; // duration value in the counterexample

        vm.expectRevert(); 
        stablePriceOracle.price(name, expires, duration);
}


}

