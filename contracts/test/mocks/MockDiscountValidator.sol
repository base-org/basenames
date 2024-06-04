//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "src/L2/interface/IDiscountValidator.sol";

contract MockDiscountValidator is IDiscountValidator {
    bool returnValue = true;

    function isValidDiscountRegistration(address, bytes calldata) external view returns (bool) {
        return returnValue;
    }

    function setReturnValue(bool value) external {
        returnValue = value;
    }
}
