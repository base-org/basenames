// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {FixedPointMathLib} from "solady/utils/FixedPointMathLib.sol";

import {EDAPrice} from "src/lib/EDAPrice.sol";
import {StablePriceOracle} from "src/L2/StablePriceOracle.sol";

/// @title Launch Auction Price Oracle
///
/// @notice The mechanism by which names are auctioned upon Basenames public launch. The RegistrarController
///     Passes the `launchTime` in place of expiry for all new names. The half life of this contract is hard-coded
///     to 1.5 hours, accomplished by bitshifting the `endValue` and by passing this period into the exponential decay
///     calculation.
///
///     Inspired by the `ExponentialPremiumPriceOracle` implemented by ENS:
///     https://github.com/ensdomains/ens-contracts/blob/staging/contracts/ethregistrar/ExponentialPremiumPriceOracle.sol
///
/// @author Coinbase (https://github.com/base-org/usernames)
contract LaunchAuctionPriceOracle is StablePriceOracle {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    /// @notice Starting premium for the dutch auction.
    uint256 public immutable startPremium;

    /// @notice Ending value of the auction, calculated on construction.
    uint256 public immutable endValue;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          CONSTANTS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice The half-life of the premium price decay in seconds.
    uint256 constant PRICE_PREMIUM_HALF_LIFE = 1.5 hours;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          ERRORS                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Thrown when the auction duration is not cleanly divisible by the auction halflife.
    error InvalidDuration();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        IMPLEMENTATION                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Construction of the premium pricing oracle.
    ///
    /// @param rentPrices The base prices passed to construction of the StablePriceOracle.
    /// @param startPremium_ The starting price for the dutch auction, denominated in wei.
    /// @param totalHours    The total duration (in hours) for the dutch auction.
    constructor(uint256[] memory rentPrices, uint256 startPremium_, uint256 totalHours) StablePriceOracle(rentPrices) {
        startPremium = startPremium_;
        if ((totalHours * 1 hours) % PRICE_PREMIUM_HALF_LIFE != 0) revert InvalidDuration();
        endValue = startPremium >> ((totalHours * 1 hours) / PRICE_PREMIUM_HALF_LIFE);
    }

    /// @notice The internal method for calculating pricing premium
    ///
    /// @dev This method handles three cases:
    ///     1. The name is not yet expired, premium = 0.
    ///     2. The name is expired and in the auction window, premium = calculated decayed premium.
    ///     3. The name is expired and outside of the auction window, premium = 0.
    ///
    /// @param expires Timestamp of when the name will expire.
    ///
    /// @return Price premium denominated in wei.
    function _premium(string memory, uint256 expires, uint256) internal view override returns (uint256) {
        if (expires > block.timestamp) {
            return 0;
        }
        uint256 elapsed = block.timestamp - expires;
        uint256 premium_ = decayedPremium(elapsed);
        if (premium_ > endValue) {
            return premium_ - endValue;
        }
        return 0;
    }

    /// @notice The mechanism for calculating the decayed premium.
    ///
    /// @param elapsed Seconds elapsed since the auction started.
    ///
    /// @return Dacayed price premium denominated in wei.
    function decayedPremium(uint256 elapsed) public view returns (uint256) {
        /// @dev 50% decay per period in wad format
        uint256 perPeriodDecayPercentWad = FixedPointMathLib.WAD / 2;
        return EDAPrice.currentPrice(startPremium, elapsed, PRICE_PREMIUM_HALF_LIFE, perPeriodDecayPercentWad);
    }
}
