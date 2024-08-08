//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {FixedPointMathLib} from "solady/utils/FixedPointMathLib.sol";
import {StablePriceOracle} from "src/L2/StablePriceOracle.sol";
import {LaunchAuctionPriceOracle} from "src/L2/LaunchAuctionPriceOracle.sol";
import {EDAPrice} from "src/lib/EDAPrice.sol";

contract LaunchAuctionPriceOracleBase is Test {
    LaunchAuctionPriceOracle oracle;

    uint256 rent1;
    uint256 rent2;
    uint256 rent3;
    uint256 rent4;
    uint256 rent5;
    uint256 rent10;

    uint256 startPremium = 100 ether;
    uint256 totalDays = 1;

    uint256 hoursPerDay = 24;

    /// @notice The half-life of the premium price decay
    uint256 constant PRICE_PREMIUM_HALF_LIFE = 1 hours;
    uint256 constant PER_PERIOD_DECAY_PERCENT_WAD = FixedPointMathLib.WAD / 2;
    uint256 constant ONE_HUNDRED_YEARS = 36_500 days;

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

        oracle = new LaunchAuctionPriceOracle(rentPrices, startPremium, totalDays);
    }

    function test_constructor() public view {
        assertEq(oracle.startPremium(), startPremium);
        assertEq(oracle.endValue(), startPremium >> (totalDays * hoursPerDay));
        assertEq(oracle.price1Letter(), rent1);
        assertEq(oracle.price2Letter(), rent2);
        assertEq(oracle.price3Letter(), rent3);
        assertEq(oracle.price4Letter(), rent4);
        assertEq(oracle.price5Letter(), rent5);
        assertEq(oracle.price10Letter(), rent10);
    }

    /// @return Returns the auction duration in seconds
    function _auctionDuration() internal view returns (uint256) {
        return totalDays * 1 days;
    }

    function _calculateDecayedPremium(uint256 elapsed) internal view returns (uint256) {
        return EDAPrice.currentPrice(startPremium, elapsed, PRICE_PREMIUM_HALF_LIFE, PER_PERIOD_DECAY_PERCENT_WAD);
    }
}
