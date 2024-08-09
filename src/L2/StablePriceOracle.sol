//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import {StringUtils} from "ens-contracts/ethregistrar/StringUtils.sol";

import {IPriceOracle} from "src/L2/interface/IPriceOracle.sol";

/// @title Stable Pricing Oracle
///
/// @notice The pricing mechanism for setting the "base price" of names on a per-letter basis.
///         Inspired by the ENS StablePriceOracle contract:
///         https://github.com/ensdomains/ens-contracts/blob/staging/contracts/ethregistrar/StablePriceOracle.sol
///
/// @author Coinbase (https://github.com/base-org/usernames)
/// @author ENS (https://github.com/ensdomains/ens-contracts)
contract StablePriceOracle is IPriceOracle {
    using StringUtils for *;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice The price for a 1 letter name per second.
    uint256 public immutable price1Letter;

    /// @notice The price for a 2 letter name per second.
    uint256 public immutable price2Letter;

    /// @notice The price for a 3 letter name per second.
    uint256 public immutable price3Letter;

    /// @notice The price for a 4 letter name per second.
    uint256 public immutable price4Letter;

    /// @notice The price for a 5 to 9 letter name per second.
    uint256 public immutable price5Letter;

    /// @notice The price for a 10 or longer letter name per second.
    uint256 public immutable price10Letter;

    /// @notice Price Oracle constructor which sets the immutably stored prices.
    ///
    /// @param _rentPrices An array of prices ordered in increasing length.
    constructor(uint256[] memory _rentPrices) {
        price1Letter = _rentPrices[0];
        price2Letter = _rentPrices[1];
        price3Letter = _rentPrices[2];
        price4Letter = _rentPrices[3];
        price5Letter = _rentPrices[4];
        price10Letter = _rentPrices[5];
    }

    /// @notice Returns the price to register or renew a name given an expiry and duration.
    ///
    /// @param name The name being registered or renewed.
    /// @param expires When the name presently expires (0 if this is a new registration).
    /// @param duration How long the name is being registered or extended for, in seconds.
    ///
    /// @return A `Price` tuple of `basePrice` and `premiumPrice`.
    function price(string calldata name, uint256 expires, uint256 duration)
        external
        view
        returns (IPriceOracle.Price memory)
    {
        uint256 len = name.strlen();
        uint256 basePrice;

        if (len >= 10) {
            basePrice = price10Letter * duration;
        } else if (len >= 5) {
            basePrice = price5Letter * duration;
        } else if (len == 4) {
            basePrice = price4Letter * duration;
        } else if (len == 3) {
            basePrice = price3Letter * duration;
        } else if (len == 2) {
            basePrice = price2Letter * duration;
        } else {
            basePrice = price1Letter * duration;
        }
        uint256 premium_ = _premium(name, expires, duration);
        return IPriceOracle.Price({base: basePrice, premium: premium_});
    }

    /// @notice Returns the pricing premium denominated in wei.
    function premium(string calldata name, uint256 expires, uint256 duration) external view returns (uint256) {
        return _premium(name, expires, duration);
    }

    /// @notice Returns the pricing premium denominated in wei.
    function _premium(string memory, uint256, uint256) internal view virtual returns (uint256) {
        return 0;
    }
}
