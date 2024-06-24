//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {ERC1155DiscountValidator} from "src/L2/discounts/ERC1155DiscountValidator.sol";

contract ERC1155DiscountValidatorBase is Test {
    
    ERC1155DiscountValidator validator;


    function setUp() public {
        validator = new ERC1155DiscountValidator();
    }
}