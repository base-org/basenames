// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IPriceOracle} from "src/L2/interface/IPriceOracle.sol";

contract MockPriceOracle is IPriceOracle {
    uint256 constant public DEFAULT_BASE_USDC = 5000000;
    uint256 constant public DEFAULT_BASE_WEI = 0.0002 ether;
    uint256 constant public DEFAULT_PREMIUM_USDC = 0;
    uint256 constant public DEFAULT_PERMIUM_WEI = 0;

    IPriceOracle.Price defaultPrice = IPriceOracle.Price({
        base_usdc: DEFAULT_BASE_USDC,
        base_wei: DEFAULT_BASE_WEI,
        premium_usdc: DEFAULT_PREMIUM_USDC,
        premium_wei: DEFAULT_PERMIUM_WEI
    });

    mapping(string => IPriceOracle.Price) prices;
    uint256 conversion = DEFAULT_BASE_WEI/DEFAULT_BASE_USDC;

    function setPrice(string calldata name, IPriceOracle.Price calldata priceData) external {
        prices[name] = priceData;
    }

    function price(string calldata name, uint256, uint256) external view returns (IPriceOracle.Price memory) {
        return (prices[name].base_usdc == 0) ? (defaultPrice) : prices[name];
    }

    function setConversion(uint256 conversion_) external {
        conversion = conversion_;
    }

    function attoUSDToWei(uint256) external view returns (uint256) {
        return conversion;
    }
}