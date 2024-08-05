// SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import {FixedPointMathLib} from "solady/utils/FixedPointMathLib.sol";

import {EDAPrice} from "src/lib/EDAPrice.sol";
import {StablePriceOracle} from "src/L2/StablePriceOracle.sol";

/// @title Launch Auction Price Oracle
///
/// @notice The mechanism by which names are auctioned upon Basenames public launch. The RegistrarController
///     Passes the `launchTime` in place of expiry for all new names. The half life of this contract is hard-coded
///     to 1 hour, accomplished by bitshifting the `endValue` and by passing this period into the exponential decay
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

    /// @notice The half-life of the premium price decay
    uint256 constant SECONDS_IN_PERIOD = 1 hours;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        IMPLEMENTATION                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Construction of the premium pricing oracle.
    ///
    /// @param rentPrices The base prices passed to construction of the StablePriceOracle.
    /// @param startPremium_ The starting price for the dutch auction, denominated in wei.
    /// @param totalDays    The total duration (in days) for the dutch auction.
    constructor(uint256[] memory rentPrices, uint256 startPremium_, uint256 totalDays) StablePriceOracle(rentPrices) {
        startPremium = startPremium_;
        endValue = startPremium >> (totalDays * 24); // 1 hour halflife
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
        uint256 premium = decayedPremium(elapsed);
        if (premium > endValue) {
            return premium - endValue;
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
        return EDAPrice.currentPrice(startPremium, elapsed, SECONDS_IN_PERIOD, perPeriodDecayPercentWad);
    }
}
