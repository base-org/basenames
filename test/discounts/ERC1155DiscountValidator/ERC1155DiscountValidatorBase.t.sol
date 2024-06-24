//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {ERC1155DiscountValidator} from "src/L2/discounts/ERC1155DiscountValidator.sol";
import {MockERC1155} from "test/mocks/MockERC1155.sol";

contract ERC1155DiscountValidatorBase is Test {
    ERC1155DiscountValidator validator;
    MockERC1155 token;
    uint256 tokenId = 1;
    address userA = makeAddr("userA");
    address userB = makeAddr("userB");

    function setUp() public {
        token = new MockERC1155();
        validator = new ERC1155DiscountValidator(address(token), tokenId);
    }
}
