// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IDiscountValidator {
    function isValidDiscountRegistration(address sender, bytes calldata validationData) external returns (bool);
}
