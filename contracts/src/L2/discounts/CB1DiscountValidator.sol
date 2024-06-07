// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Ownable} from "solady/auth/Ownable.sol";

import {IDiscountValidator} from "src/L2/interface/IDiscountValidator.sol";

contract CB1DiscountValidator is Ownable, IDiscountValidator {

    address signer;

    constructor(address signer_, address owner_) {
        signer = signer_;
        _initializeOwner(owner_);
    }

    /// @notice Required implementation for compatibility with IDiscountValidator.
    ///
    /// @dev The validationData must be formed according to the following:
    ///     `bytes validationData = abi.encode(discountClaimerAddress, expiry, signature_bytes)`.
    ///      where the signature is a result of the stored `signer` signing a message hash formed by:  
    ///      `hash =  keccak256(abi.encode(hex"0x1900", trustedSignerAddress, discountClaimerAddress, expiry))`.
    ///      
    /// @param sender  the discount claimer's address.
    /// @param validationData opaque bytes for performing the validation.
    ///
    /// @return `true` if the validation data provided is determined to be valid for the specified sender, else `false.
    function isValidDiscountRegistration(address sender, bytes calldata validationData) external returns (bool) {
        (address claimaint, uint64 expires, bytes memory sig) = abi.decode(validationData, (address, uint64, bytes));
    }


}

