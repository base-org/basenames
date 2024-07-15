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
        uint256[] memory rentPrices = new uint256[](6);

        rent1 = 316_808_781_402;
        rent2 = 31_680_878_140;
        rent3 = 3_168_087_814;
        rent4 = 316_808_781;
        rent5 = 31_680_878;
        rent10 = 3_168_087; // 3,168,808.781402895 = 1e14 / (365.25 * 24 * 3600)

        rentPrices[0] = rent1;
        rentPrices[1] = rent2;
        rentPrices[2] = rent3;
        rentPrices[3] = rent4;
        rentPrices[4] = rent5;
        rentPrices[5] = rent10;

        stablePriceOracle = new StablePriceOracle(rentPrices);
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
