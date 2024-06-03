//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import {Test, console} from "forge-std/Test.sol";
import {StablePriceOracle} from "src/L2/StablePriceOracle.sol";

contract StablePriceOracleBase is Test {
    StablePriceOracle stablePriceOracle;

    uint256 rent1;
    uint256 rent2;
    uint256 rent3;
    uint256 rent4;
    uint256 rent5;
    uint256 rent10;

    function setUp() public {

        uint256[] memory rentPrices = new uint256[](5);

        rent1 = 1E19;
        rent2 = 1E18;
        rent3 = 1E17;
        rent4 = 1E16;
        rent5 = 1E15;
        rent10 = 1E14;

        rentPrices[0] = rent1;
        rentPrices[1] = rent2;
        rentPrices[2] = rent3;
        rentPrices[3] = rent4;
        rentPrices[4] = rent5;
        rentPrices[5] = rent10;
    }

    function test_constructor() public view {

        assertEq(stablePriceOracle.price1Letter(), rent1);
        assertEq(stablePriceOracle.price2Letter(), rent2);
        assertEq(stablePriceOracle.price3Letter(), rent3);
        assertEq(stablePriceOracle.price4Letter(), rent4);
        assertEq(stablePriceOracle.price5Letter(), rent5);
        assertEq(stablePriceOracle.price10Letter(), rent10);
    }

}