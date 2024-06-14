//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import {Test, console} from "forge-std/Test.sol";
import {ExponentialPremiumOracleBase} from "./ExponentialPremiumOracleBase.t.sol";
import "solady/utils/FixedPointMathLib.sol";

contract DecayedPremium is ExponentialPremiumOracleBase {
    function test_decayedPremium_zeroElapsed() public view {
        uint256 elapsed = 0;
        uint256 expectedPremium = startPremium;
        uint256 actualPremium = oracle.decayedPremium(elapsed);
        assertEq(actualPremium, expectedPremium);
    }

    function test_decayedPremium_halfPeriod() public view {
        uint256 elapsed = 1 days / 2;
        uint256 expectedPremium = 707106781186547524; // Calculated expected value for premium price after 1/2 day
        uint256 actualPremium = oracle.decayedPremium(elapsed);
        assertEq(actualPremium, expectedPremium);
    }

    function test_decayedPremium_threePeriods() public view {
        uint256 elapsed = 3 days;
        uint256 expectedPremium = 124999999999999999; // Calculated expected value for premium price after 3 days
        uint256 actualPremium = oracle.decayedPremium(elapsed);
        assertEq(actualPremium, expectedPremium);
    }
}
