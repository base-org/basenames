//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test, console} from "forge-std/Test.sol";
import {StablePriceOracle} from "src/L2/StablePriceOracle.sol";
import {MockOracle} from "../mocks/MockOracle.sol";

contract StablePriceFuzzTest is Test {
    StablePriceOracle stablePriceOracle;
    MockOracle mockOracle;

    function setUp() public {
        uint256 fuzzedPrice = uint256(keccak256(abi.encodePacked(block.timestamp, gasleft()))) % 1e18;
        mockOracle = new MockOracle(int256(fuzzedPrice));

        uint256[] memory rentPrices = new uint256[](5);
        for (uint256 i = 0; i < 5; i++) {
            rentPrices[i] = uint256(keccak256(abi.encodePacked(block.timestamp, gasleft(), i))) % 1e6;
        }
        stablePriceOracle = new StablePriceOracle(mockOracle, rentPrices);
    }

    function test_price_reverts_unicodeCharacters() public { // Test case for the failed fuzz test to determine which field is causing the error
    
        string memory name = unicode"𐏔Ⱥs%𝔵b.ハ|\"*༸&`"; // Erroring on input with Unicode characters

        uint256 expires = 32987790711288265998887799860420900946; // expires value in the counterexample 

        uint256 duration = 120886407775381395340616426642328538404563530755442021068989041128827069110; // duration value in the counterexample

        vm.expectRevert(); 
        stablePriceOracle.price(name, expires, duration);
}

    function test_price(string memory name, uint256 expires, uint256 duration) public view {
        vm.assume(bytes(name).length > 0 && bytes(name).length <= 512);
        // vm.assume(isValidUnicodeString(name));
        stablePriceOracle.price(name, expires, duration);
    }

    // function isValidUnicodeString(string memory str) internal pure returns (bool) {
    // bytes memory b = bytes(str);
    // for (uint i = 0; i < b.length; i++) {
    //     bytes1 char = b[i];
    //     if (char >= 0x80) {
    //         if (char < 0xC2 || char > 0xF4) {
    //             return false;
    //         }
    //         i++;
    //         if (i >= b.length || b[i] < 0x80 || b[i] > 0xBF) {
    //             return false;
    //         }
    //     }
    // }
    // return true;
    // }

    function test_AttoUSDToWei(uint256 attoUSD) public view{
        uint256 scaledAttoUSD = attoUSD / 1e10;
        stablePriceOracle.attoUSDToWei(scaledAttoUSD);
    }
    
}