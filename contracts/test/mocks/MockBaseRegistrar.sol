// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract MockBaseRegistrar {
    mapping(uint256 => bool) availability;
    mapping(uint256 => uint256) expiries;

    function setAvailable(uint256 label, bool available_) external {
        availability[label] = available_;
    }

    function available(uint256 label) external view returns (bool) {
        return availability[label];
    }

    function setNameExpires(uint256 label, uint256 expiry) external {
        expiries[label] = expiry;
    }

    function nameExpires(uint256 label) external view returns (uint256) {
        return expiries[label];
    }
}