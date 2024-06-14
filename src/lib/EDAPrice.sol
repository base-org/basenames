// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {FixedPointMathLib} from "src/lib/FixedPointMathLib.sol";

library EDAPrice {
    /// @notice returns the current price of an exponential price decay auction defined by the passed params
    /// @dev reverts if perPeriodDecayPercentWad >= 1e18
    /// @dev reverts if uint256 secondsInPeriod = 0
    /// @dev reverts if startPrice * multiplier overflows
    /// @dev reverts if lnWad(percentWadRemainingPerPeriod) * ratio) overflows
    /// @param startPrice the starting price of the auction
    /// @param secondsElapsed the seconds elapsed since auction start
    /// @param secondsInPeriod the seconds over which the price should decay perPeriodDecayPercentWad
    /// @param perPeriodDecayPercentWad the percent the price should decay during secondsInPeriod, 100% = 1e18
    /// @return price the current auction price
    function currentPrice(
        uint256 startPrice,
        uint256 secondsElapsed,
        uint256 secondsInPeriod,
        uint256 perPeriodDecayPercentWad
    ) internal pure returns (uint256) {
        uint256 ratio = FixedPointMathLib.divWadDown(secondsElapsed, secondsInPeriod);
        uint256 percentWadRemainingPerPeriod = FixedPointMathLib.WAD - perPeriodDecayPercentWad;
        // percentWadRemainingPerPeriod can be safely cast because < 1e18
        // ratio can be safely cast because will not overflow unless ratio > int256.max,
        // which would require secondsElapsed > int256.max, i.e. > 5.78e76 or 1.8e69 years
        uint256 multiplier = percentWadRemainingPerPeriod ** ratio;
        // casting to uint256 is safe because percentWadRemainingPerPeriod is non negative
        uint256 price = startPrice * uint256(multiplier);
        return (price / FixedPointMathLib.WAD);
    }
}