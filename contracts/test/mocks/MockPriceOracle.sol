// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IPriceOracle} from "src/L2/interface/IPriceOracle.sol";

contract MockPriceOracle is IPriceOracle {
    uint256 public constant DEFAULT_BASE_WEI = 0.1 ether;
    uint256 public constant DEFAULT_PERMIUM_WEI = 0;

    IPriceOracle.Price defaultPrice = IPriceOracle.Price({base: DEFAULT_BASE_WEI, premium: DEFAULT_PERMIUM_WEI});

    mapping(string => IPriceOracle.Price) prices;

    function setPrice(string calldata name, IPriceOracle.Price calldata priceData) external {
        prices[name] = priceData;
    }

    function price(string calldata name, uint256, uint256) external view returns (IPriceOracle.Price memory) {
        return (prices[name].base == 0) ? (defaultPrice) : prices[name];
    }
}
