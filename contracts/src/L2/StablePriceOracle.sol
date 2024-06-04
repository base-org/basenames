//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import {StringUtils} from "ens-contracts/ethregistrar/StringUtils.sol";

import {IPriceOracle} from "src/L2/interface/IPriceOracle.sol";

// StablePriceOracle sets a price in wei
contract StablePriceOracle is IPriceOracle {
    using StringUtils for *;

    // Rent in wei by length
    uint256 public immutable price1Letter;
    uint256 public immutable price2Letter;
    uint256 public immutable price3Letter;
    uint256 public immutable price4Letter;
    uint256 public immutable price5Letter;
    uint256 public immutable price10Letter;

    constructor(uint256[] memory _rentPrices) {
        price1Letter = _rentPrices[0];
        price2Letter = _rentPrices[1];
        price3Letter = _rentPrices[2];
        price4Letter = _rentPrices[3];
        price5Letter = _rentPrices[4];
        price10Letter = _rentPrices[5];
    }

    /**
     * @dev Returns the price to register or renew a name.
     * @param name The name being registered or renewed.
     * @param expires When the name presently expires (0 if this is a new registration).
     * @param duration How long the name is being registered or extended for, in seconds.
     * @return base premium tuple of base price + premium price
     */
    function price(string calldata name, uint256 expires, uint256 duration)
        external
        view
        returns (IPriceOracle.Price memory)
    {
        uint256 len = name.strlen();
        uint256 basePrice;

        if (len >= 10) {
            basePrice = price10Letter * duration;
        } else if (len >= 5 && len < 10) {
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

    /**
     * @dev Returns the pricing premium in wei.
     */
    function premium(string calldata name, uint256 expires, uint256 duration) external view returns (uint256) {
        return _premium(name, expires, duration);
    }

    /**
     * @dev Returns the pricing premium in internal base units.
     */
    function _premium(string memory, uint256, uint256) internal view virtual returns (uint256) {
        return 0;
    }
}
