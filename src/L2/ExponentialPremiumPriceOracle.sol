// SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import {FixedPointMathLib} from "solady/utils/FixedPointMathLib.sol";

import {EDAPrice} from "src/lib/EDAPrice.sol";
import {StablePriceOracle} from "src/L2/StablePriceOracle.sol";

contract ExponentialPremiumPriceOracle is StablePriceOracle {
    /// @dev The starting price of the dutch auction, denominated in wei.
    uint256 public immutable startPremium;

    /// @dev The calculated ending value of the dutch auction, denominated in wei.
    uint256 public immutable endValue;

    /// @dev The half-life of the premium price decay
    uint256 public immutable secondsInPeriod;

    error InvlaidPeriod();

    constructor(uint256[] memory rentPrices, uint256 startPremium_, uint256 totalDays, uint256 secondsInPeriod_)
        StablePriceOracle(rentPrices)
    {
        if (secondsInPeriod_ > 1 days) revert InvlaidPeriod();
        startPremium = startPremium_;
        secondsInPeriod = secondsInPeriod_;
        endValue = startPremium >> ((totalDays * 1 days) / secondsInPeriod_);
    }

    /**
     * @dev Returns the pricing premium in internal base units.
     */
    function _premium(string memory, uint256 expires, uint256) internal view override returns (uint256) {
        if (expires > block.timestamp) {
            return 0;
        }
        uint256 elapsed = block.timestamp - expires;
        uint256 premium = decayedPremium(elapsed);
        if (premium > endValue) {
            return premium - endValue;
        }
        return 0;
    }

    /**
     * @dev Returns the premium price at current time elapsed
     * @param elapsed time past since expiry
     */
    function decayedPremium(uint256 elapsed) public view returns (uint256) {
        /// @dev 50% decay per period in wad format
        uint256 perPeriodDecayPercentWad = FixedPointMathLib.WAD / 2;
        uint256 premium = EDAPrice.currentPrice(startPremium, elapsed, secondsInPeriod, perPeriodDecayPercentWad);
        return premium;
    }
}
