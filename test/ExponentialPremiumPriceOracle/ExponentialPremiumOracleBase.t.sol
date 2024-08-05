//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import {Test, console} from "forge-std/Test.sol";
import {StablePriceOracle} from "src/L2/StablePriceOracle.sol";
import {ExponentialPremiumPriceOracle} from "src/L2/ExponentialPremiumPriceOracle.sol";

contract ExponentialPremiumOracleBase is Test {
    ExponentialPremiumPriceOracle oracle;

    uint256 rent1;
    uint256 rent2;
    uint256 rent3;
    uint256 rent4;
    uint256 rent5;
    uint256 rent10;

    uint256 startPremium = 1e18;
    uint256 totalDays = 21;

    function setUp() public {
        uint256[] memory rentPrices = new uint256[](6);

        rent1 = 1e18;
        rent2 = 2e18;
        rent3 = 3e18;
        rent4 = 4e18;
        rent5 = 5e18;
        rent10 = 6e18;

        rentPrices[0] = rent1;
        rentPrices[1] = rent2;
        rentPrices[2] = rent3;
        rentPrices[3] = rent4;
        rentPrices[4] = rent5;
        rentPrices[5] = rent10;

        oracle = new ExponentialPremiumPriceOracle(rentPrices, startPremium, totalDays);
    }

    function test_constructor() public view {
        assertEq(oracle.startPremium(), startPremium);
        assertEq(oracle.endValue(), startPremium >> totalDays);
        assertEq(oracle.price1Letter(), rent1);
        assertEq(oracle.price2Letter(), rent2);
        assertEq(oracle.price3Letter(), rent3);
        assertEq(oracle.price4Letter(), rent4);
        assertEq(oracle.price5Letter(), rent5);
        assertEq(oracle.price10Letter(), rent10);
    }
}
