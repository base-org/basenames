//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test, console} from "forge-std/Test.sol";
import "src/L2/StablePriceOracle.sol";
import "../mocks/MockOracle.sol";

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

    function testFailingCase() public view { // Test case for the failed fuzz test
    string memory name = "Hello"; // "𐏔Ⱥs%𝔵b.ハ|\"*༸&`" Erroring on input with Unicode characters
    uint256 expires = 32987790711288265998887799860420900946;
    uint256 duration = 120886407775381395340616426642328538404563530755442021068989041128827069110;

    stablePriceOracle.price(name, expires, duration);
}
    function testFuzzPrice(string memory name, uint256 expires, uint256 duration) public {
        stablePriceOracle.price(name, expires, duration);
    }
    function testFuzzAttoUSDToWei(uint256 attoUSD) public {
        uint256 scaledAttoUSD = attoUSD / 1e10;
        stablePriceOracle.attoUSDToWei(scaledAttoUSD);
    }
    
}