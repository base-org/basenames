//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import {StringUtils} from "ens-contracts/ethregistrar/StringUtils.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {IPriceOracle} from "./interface/IPriceOracle.sol";

interface AggregatorInterface {
    function latestAnswer() external view returns (int256);
}

// StablePriceOracle sets a price in USD, based on an oracle.
contract StablePriceOracle is IPriceOracle {
    using StringUtils for *;

    // Rent in USDC by length
    uint256 public immutable price1Letter;
    uint256 public immutable price2Letter;
    uint256 public immutable price3Letter;
    uint256 public immutable price4Letter;
    uint256 public immutable price5Letter;

    // Oracle address
    AggregatorInterface public immutable usdOracle;

    constructor(AggregatorInterface _usdOracle, uint256[] memory _rentPrices) {
        usdOracle = _usdOracle;
        price1Letter = _rentPrices[0];
        price2Letter = _rentPrices[1];
        price3Letter = _rentPrices[2];
        price4Letter = _rentPrices[3];
        price5Letter = _rentPrices[4];
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

        if (len >= 5) {
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
        return IPriceOracle.Price({
            base_usdc: basePrice,
            premium_usdc: premium_,
            base_wei: attoUSDToWei(basePrice),
            premium_wei: attoUSDToWei(premium_)
        });
    }

    /**
     * @dev Returns the pricing premium in wei.
     */
    function premium(string calldata name, uint256 expires, uint256 duration) external view returns (uint256) {
        return attoUSDToWei(_premium(name, expires, duration));
    }

    /**
     * @dev Returns the pricing premium in internal base units.
     */
    function _premium(string memory, uint256, uint256) internal view virtual returns (uint256) {
        return 0;
    }

    function attoUSDToWei(uint256 amount) public view returns (uint256) {
        uint256 ethPrice = uint256(usdOracle.latestAnswer());
        return (amount * 1e8) / ethPrice;
    }

    function weiToAttoUSD(uint256 amount) internal view returns (uint256) {
        uint256 ethPrice = uint256(usdOracle.latestAnswer());
        return (amount * ethPrice) / 1e8;
    }
}
