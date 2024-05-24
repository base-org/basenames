//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "src/L2/interface/IDiscountValidator.sol";

contract MockDiscountValidtor is IDiscountValidator {
    function isValidDiscountRegistration(address, bytes calldata) external returns (bool) {
        return true;
    }
}
