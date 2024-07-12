//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {ERC721DiscountValidator} from "src/L2/discounts/ERC721DiscountValidator.sol";
import {MockERC721} from "test/mocks/MockERC721.sol";

contract ERC721DiscountValidatorBase is Test {
    ERC721DiscountValidator validator;
    MockERC721 token;
    address userA = makeAddr("userA");
    address userB = makeAddr("userB");

    function setUp() public {
        token = new MockERC721();
        validator = new ERC721DiscountValidator(address(token));
    }
}
