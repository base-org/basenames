//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test, console} from "forge-std/Test.sol";
import {StablePriceOracle} from "src/L2/StablePriceOracle.sol";
import {IPriceOracle} from "src/L2/interface/IPriceOracle.sol";
import {StablePriceOracleBase} from "./StablePriceOracleBase.t.sol";

contract Price is StablePriceOracleBase {
    uint256 duration = 365 days;
    function test_price_calculatePrice_oneLetter() public view {
        IPriceOracle.Price memory price1 = stablePriceOracle.price("a", 0, duration);
        assertEq(price1.base, rent1 * duration);
        assertEq(price1.premium, 0); 
    }

    function test_price_calculatesPrice_twoLetters() public view { 
        IPriceOracle.Price memory price2 = stablePriceOracle.price("ab", 0, duration);
        assertEq(price2.base, rent2 * duration);
        assertEq(price2.premium, 0);
    }

    function test_price_calculatesPrice_threeLetters() public view { 
        IPriceOracle.Price memory price3 = stablePriceOracle.price("abc", 0, duration);
        assertEq(price3.base, rent3 * duration);
        assertEq(price3.premium, 0); 
    }

    function test_price_calculatesPrice_fourLetters() public view { 
        IPriceOracle.Price memory price4 = stablePriceOracle.price("abcd", 0, duration);
        assertEq(price4.base, rent4 * duration);
        assertEq(price4.premium, 0); 
    }

    function test_price_calculatesPrice_fiveLetters() public view { 
        IPriceOracle.Price memory price5 = stablePriceOracle.price("abcde", 0, duration);
        assertEq(price5.base, rent5 * duration);
        assertEq(price5.premium, 0); 
    }

    function test_price_calculatesPrice_tenLetters() public view { 
        IPriceOracle.Price memory price10 = stablePriceOracle.price("abcdefghij", 0, duration);
        assertEq(price10.base, rent10 * duration);
        assertEq(price10.premium, 0); 
    }

    function test_price_calculatesPrice_moreThanFive_lessThanTenLetters() public view { 
        IPriceOracle.Price memory price6 = stablePriceOracle.price("abcdef", 0, duration);
        assertEq(price6.base, rent5 * duration);
    }

    function test_price_calculatesPrice_moreThanTenLetters() public view { 
        IPriceOracle.Price memory price11 = stablePriceOracle.price("abcdefghijk", 0, duration);
        assertEq(price11.base, rent10 * duration);
    }

    function test_price_reverts_unicodeCharacters() public { // Test case for the failed fuzz test to determine which field is causing the error
    
        string memory name = unicode"𐏔Ⱥs%𝔵b.ハ|\"*༸&`"; // Erroring on input with Unicode characters

        uint256 expires = 32987790711288265998887799860420900946; // expires value in the counterexample 

        uint256 duration = 120886407775381395340616426642328538404563530755442021068989041128827069110; // duration value in the counterexample

        vm.expectRevert(); 
        stablePriceOracle.price(name, expires, duration);
}


}

