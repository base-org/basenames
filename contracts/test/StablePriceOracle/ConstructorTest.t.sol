//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import {Test, console} from "forge-std/Test.sol";
import {StablePriceOracle} from "src/L2/StablePriceOracle.sol";
import {MockOracle} from "../mocks/MockOracle.sol";

contract StablePriceOracleBase is Test {
    StablePriceOracle stablePriceOracle;
    MockOracle mockOracle;

    uint256 rent1;
    uint256 rent2;
    uint256 rent3;
    uint256 rent4;
    uint256 rent5;

    function setUp() public {
        int256 mockEthPrice = 3000;
        mockOracle = new MockOracle(mockEthPrice);

        uint256[] memory rentPrices = new uint256[](5);

        rent1 = 1000000;
        rent2 = 2000000;
        rent3 = 3000000;
        rent4 = 4000000;
        rent5 = 5000000;

        rentPrices[0] = rent1;
        rentPrices[1] = rent2;
        rentPrices[2] = rent3;
        rentPrices[3] = rent4;
        rentPrices[4] = rent5;
        stablePriceOracle  = new StablePriceOracle(mockOracle, rentPrices);
    }

    function test_constructor() public view {
        assertEq(address(stablePriceOracle.usdOracle()), address(mockOracle));

        assertEq(stablePriceOracle.price1Letter(), rent1);
        assertEq(stablePriceOracle.price2Letter(), rent2);
        assertEq(stablePriceOracle.price3Letter(), rent3);
        assertEq(stablePriceOracle.price4Letter(), rent4);
        assertEq(stablePriceOracle.price5Letter(), rent5);
    }

}