//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import {Test, console} from "forge-std/Test.sol";
import "src/L2/StablePriceOracle.sol";
import "../mocks/MockOracle.sol";

contract StablePriceOracleTest is Test {
    StablePriceOracle stablePriceOracle;
    MockOracle mockOracle;

    uint256 rent1;
    uint256 rent2;
    uint256 rent3;
    uint256 rent4;
    uint256 rent5;

    function setUp() public {
        mockOracle = new MockOracle(3000);

        uint256[] memory rentPrices = new uint256[](5);

        rent1 = 1000000;
        rent2 = 2000000;
        rent3 = 3000000;
        rent4 = 4000000;
        rent5 = 5000000;

        rentPrices[0] = 1000000;
        rentPrices[1] = 2000000;
        rentPrices[2] = 3000000;
        rentPrices[3] = 4000000;
        rentPrices[4] = 5000000;
        stablePriceOracle  = new StablePriceOracle(mockOracle, rentPrices);
    }

    function test_constructor() public view {
        assertEq(address(stablePriceOracle.usdOracle()), address(mockOracle));

        assertEq(stablePriceOracle.price1Letter(), 1000000);
        assertEq(stablePriceOracle.price2Letter(), 2000000);
        assertEq(stablePriceOracle.price3Letter(), 3000000);
        assertEq(stablePriceOracle.price4Letter(), 4000000);
        assertEq(stablePriceOracle.price5Letter(), 5000000);
    }

}