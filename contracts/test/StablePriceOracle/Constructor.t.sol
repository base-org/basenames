//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import {Test, console} from "forge-std/Test.sol";
import "src/L2/StablePriceOracle.sol";
import "../mocks/MockOracle.sol";

contract StablePriceOracleTest is Test {
    StablePriceOracle stablePriceOracle;
    MockOracle mockOracle;

    function setUp() public {
        mockOracle = new MockOracle(15000000);

        uint256[] memory rentPrices = new uint256[](5);

        rentPrices[0] = 1000000;
        rentPrices[1] = 2000000;
        rentPrices[2] = 3000000;
        rentPrices[3] = 4000000;
        rentPrices[4] = 5000000;
        stablePriceOracle  = new StablePriceOracle(mockOracle, rentPrices);
    }

    function testConstructor() public view {
        assertEq(address(stablePriceOracle.usdOracle()), address(mockOracle));

        assertEq(stablePriceOracle.price1Letter(), 1000000);
        assertEq(stablePriceOracle.price2Letter(), 2000000);
        assertEq(stablePriceOracle.price3Letter(), 3000000);
        assertEq(stablePriceOracle.price4Letter(), 4000000);
        assertEq(stablePriceOracle.price5Letter(), 5000000);
    }

    // function testConstructorZeroAddress() public {
    //     uint256[] memory rentPrices = new uint256[](5);

    //     rentPrices[0] = 1000000;
    //     rentPrices[1] = 2000000;
    //     rentPrices[2] = 3000000;
    //     rentPrices[3] = 4000000;
    //     rentPrices[4] = 5000000;
    //     vm.expectRevert("Address can't be zero");
    //     new StablePriceOracle(AggregatorInterface(address(0)), rentPrices);
    // }
    // function testConstructorEmptyRentPrices() public {
    //     uint256[] memory rentPrices = new uint256[](0);
    //     vm.expectRevert("Rent prices array length mismatch");
    // }
}