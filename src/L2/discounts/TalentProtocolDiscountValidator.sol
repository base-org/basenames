//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {IDiscountValidator} from "src/L2/interface/IDiscountValidator.sol";


/// @title Discount Validator for: Talent Protocol Builder Score
///
/// @notice TODO
///
/// @author Coinbase (https://github.com/base-org/usernames)
contract TalentProtocolDiscountValidator is IDiscountValidator {

    address immutable talentProtocol;

    constructor(address talentProtocol_) {
        talentProtocol = talentProtocol_;
    }

    function isValidDiscountRegistration(address claimer, bytes calldata) external view returns (bool) {
        return (talentProtocol.balanceOf(claimer) > 0);
    }
}