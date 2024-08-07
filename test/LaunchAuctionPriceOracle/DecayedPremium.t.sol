//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import {Test} from "forge-std/Test.sol";
import {LaunchAuctionPriceOracleBase} from "./LaunchAuctionPriceOracleBase.t.sol";
import {FixedPointMathLib} from "solady/utils/FixedPointMathLib.sol";

contract DecayedPremium is LaunchAuctionPriceOracleBase {
    function test_decayedPremium_zeroElapsed() public view {
        uint256 elapsed = 0;
        uint256 expectedPremium = startPremium;
        uint256 actualPremium = oracle.decayedPremium(elapsed);
        assertEq(actualPremium, expectedPremium);
    }

    function test_decayedPremium_boundaryConditions() public view {
        uint256 zeroElapsedPremium = oracle.decayedPremium(0);
        assertEq(zeroElapsedPremium, startPremium);

        uint256 auctionEndPremium = oracle.decayedPremium(totalDays * 1 days);
        assertTrue(auctionEndPremium < oracle.endValue());
    }

    function test_decayedPremium_halfPeriod() public view {
        uint256 elapsed = 1 hours / 2;
        uint256 expectedPremium = 70710678118654752400; // Calculated expected value for premium price after 1/2 day
        uint256 actualPremium = oracle.decayedPremium(elapsed);
        assertEq(actualPremium, expectedPremium);
    }

    function test_decayedPremium_threePeriods() public view {
        uint256 elapsed = 3 hours;
        uint256 expectedPremium = 12499999999999999900; // Calculated expected value for premium price after 3 days
        uint256 actualPremium = oracle.decayedPremium(elapsed);
        assertEq(actualPremium, expectedPremium);
    }
}
