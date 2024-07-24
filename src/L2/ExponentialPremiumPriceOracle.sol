// SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import {FixedPointMathLib} from "solady/utils/FixedPointMathLib.sol";

import {EDAPrice} from "src/lib/EDAPrice.sol";
import {StablePriceOracle} from "src/L2/StablePriceOracle.sol";

contract ExponentialPremiumPriceOracle is StablePriceOracle {
    uint256 public immutable startPremium;
    uint256 public immutable endValue;

    constructor(uint256[] memory rentPrices, uint256 startPremium_, uint256 totalDays) StablePriceOracle(rentPrices) {
        startPremium = startPremium_;
        endValue = startPremium >> totalDays;
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
        /// @dev The half-life of the premium price decay
        uint256 secondsInPeriod = 1 days;
        /// @dev 50% decay per period in wad format
        uint256 perPeriodDecayPercentWad = FixedPointMathLib.WAD / 2;
        uint256 premium = EDAPrice.currentPrice(startPremium, elapsed, secondsInPeriod, perPeriodDecayPercentWad);
        return premium;
    }
}
