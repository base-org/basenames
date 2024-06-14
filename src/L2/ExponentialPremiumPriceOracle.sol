pragma solidity ~0.8.17;

import "./StablePriceOracle.sol";
import {GRACE_PERIOD} from "src/util/Constants.sol";
import {EDAPrice} from "src/lib/EDAPrice.sol";
import {FixedPointMathLib} from "src/lib/FixedPointMathLib.sol";

contract ExponentialPremiumPriceOracle is StablePriceOracle {
    uint256 immutable startPremium;
    uint256 immutable endValue;

    constructor(uint256[] memory rentPrices, uint256 startPremium, uint256 totalDays) StablePriceOracle(rentPrices) {
        startPremium = startPremium;
        endValue = startPremium_ >> totalDays;
    }

    uint256 constant PRECISION = 1e18;

    /**
     * @dev Returns the pricing premium in internal base units.
     */
    function _premium(string memory, uint256 expires, uint256) internal view override returns (uint256) {
        expires = expires + GRACE_PERIOD;
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
        uint256 secondsInPeriod = 1 days;
        uint256 perPeriodDecayPercentWad = FixedPointMathLib.WAD/2;
        uint256 premium = EDAPrice.currentPrice(startPremium, elapsed, secondsInPeriod, perPeriodDecayPercentWad);
        return premium;
    }

}

