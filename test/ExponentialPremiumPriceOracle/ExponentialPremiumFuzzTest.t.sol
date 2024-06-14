//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import {Test, console} from "forge-std/Test.sol";
import {ExponentialPremiumOracleBase} from "./ExponentialPremiumOracleBase.t.sol";
import "solady/utils/FixedPointMathLib.sol";

contract ExponentialPremiumFuzzTest is ExponentialPremiumOracleBase {
    function test_decayedPremium_decreasingPrices(uint256 elapsed) public view {
        vm.assume(elapsed <= 365 days);
        uint256 actualPremium = oracle.decayedPremium(elapsed);
        assert(actualPremium <= startPremium);
    }

    function test_decayedPremium_boundaryValues(uint256 elapsed) public view {
        uint256[] memory boundaryValues = new uint256[](3);
        boundaryValues[0] = 0;
        boundaryValues[1] = 1 days;
        boundaryValues[2] = 365 days;

        for (uint256 i = 0; i < boundaryValues.length; i++) {
            elapsed = boundaryValues[i];
            uint256 actualPremium = oracle.decayedPremium(elapsed);
            assert(actualPremium <= startPremium);
        }
    }

    function test_decayedPremium_alwaysDecreasing(uint256 elapsed1, uint256 elapsed2) public view {
        vm.assume(elapsed1 <= elapsed2);
        vm.assume(elapsed2 <= 365 days);

        uint256 premium1 = oracle.decayedPremium(elapsed1);
        uint256 premium2 = oracle.decayedPremium(elapsed2);

        assert(premium1 >= premium2);
    }
}
