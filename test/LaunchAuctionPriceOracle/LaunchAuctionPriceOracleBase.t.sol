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
    uint256 totalHours = 36;

    /// @notice The half-life of the premium price decay
    uint256 constant PRICE_PREMIUM_HALF_LIFE = 1.5 hours;
    uint256 constant PER_PERIOD_DECAY_PERCENT_WAD = FixedPointMathLib.WAD / 2;
    uint256 constant ONE_HUNDRED_YEARS = 36_500 days;

    function setUp() public {
        oracle = new LaunchAuctionPriceOracle(_getRentPrices(), startPremium, totalHours);
    }

    function test_constructor() public view {
        assertEq(oracle.startPremium(), startPremium);
        assertEq(oracle.endValue(), startPremium >> ((totalHours * 1 hours) / PRICE_PREMIUM_HALF_LIFE));
        assertEq(oracle.price1Letter(), rent1);
        assertEq(oracle.price2Letter(), rent2);
        assertEq(oracle.price3Letter(), rent3);
        assertEq(oracle.price4Letter(), rent4);
        assertEq(oracle.price5Letter(), rent5);
        assertEq(oracle.price10Letter(), rent10);
    }

    function test_constructorReverts_whenInvalidDuration() public {
        vm.expectRevert(LaunchAuctionPriceOracle.InvalidDuration.selector);
        new LaunchAuctionPriceOracle(_getRentPrices(), startPremium, totalHours + 1);
    }

    function _getRentPrices() internal returns (uint256[] memory) {
        uint256[] memory rentPrices = new uint256[](6);

        /// @dev These are the per-second prices (wei/s) for various letter lengths, i.e.
        ///     1-letter == rent1, 2-letter == rent2, etc.
        ///     The price values are set so that the annual pricing matches our product prices:
        ///     0.1 ETH for a 3-letter name, 0.01 ETH for a 4-letter name, etc...
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

        return rentPrices;
    }

    /// @return Returns the auction duration in seconds
    function _auctionDuration() internal view returns (uint256) {
        return totalHours * 1 hours;
    }

    function _calculateDecayedPremium(uint256 elapsed) internal view returns (uint256) {
        return EDAPrice.currentPrice(startPremium, elapsed, PRICE_PREMIUM_HALF_LIFE, PER_PERIOD_DECAY_PERCENT_WAD);
    }
}
