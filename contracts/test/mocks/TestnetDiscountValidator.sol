// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {IDiscountValidator} from "src/L2/interface/IDiscountValidator.sol";

contract TestnetDiscountValidator is IDiscountValidator {
    function isValidDiscountRegistration(address, bytes calldata) external pure returns (bool) {
        return true;
    }
}
