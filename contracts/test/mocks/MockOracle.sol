//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

contract MockOracle {
    int256 private price;

    constructor(int256 _initialPrice) {
        price = _initialPrice;
    }
    function latestAnswer() external view returns (int256) {
        return price;
    }
    function setPrice(int256 _newPrice) external {
        price = _newPrice;
    }
}