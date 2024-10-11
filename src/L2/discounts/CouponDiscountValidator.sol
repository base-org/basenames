//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ECDSA} from "solady/utils/ECDSA.sol";
import {Ownable} from "solady/auth/Ownable.sol";

import {IDiscountValidator} from "src/L2/interface/IDiscountValidator.sol";

/// @title Discount Validator for: Coinbase Attestation Validator
///
/// @notice Implements a two step validation schema for verifying coinbase attestations
///         1. Verify that the wallet has an active Coinbase Verification for the stored `schemaID`.
///         2. Signature verification to valiate signatures from the Coinbase sybil resistance service.
///         https://github.com/coinbase/verifications
///
/// @author Coinbase (https://github.com/base-org/usernames)
contract CouponDiscountValidator is Ownable, IDiscountValidator {
    /// @dev The attestation service signer.
    address signer;

    /// @notice Thrown when the signature expiry date >= block.timestamp.
    error SignatureExpired();

    /// @notice Attestation Validator constructor
    ///
    /// @param owner_ The permissioned `owner` in the `Ownable` context.
    /// @param signer_ The off-chain signer of the Coinbase sybil resistance service.
    constructor(address owner_, address signer_) {
        _initializeOwner(owner_);
        signer = signer_;
    }

    /// @notice Allows the owner to update the expected signer.
    ///
    /// @param signer_ The address of the new signer.
    function setSigner(address signer_) external onlyOwner {
        signer = signer_;
    }

    /// @notice Required implementation for compatibility with IDiscountValidator.
    ///
    /// @dev The data must be encoded as `abi.encode(discountClaimerAddress, expiry, signature_bytes)`.
    ///
    /// @param validationData opaque bytes for performing the validation.
    ///
    /// @return `true` if the validation data provided is determined to be valid for the specified claimer, else `false`.
    function isValidDiscountRegistration(address, bytes calldata validationData) external view returns (bool) {
        (uint64 expiry, bytes32 uuid, uint256 salt, bytes memory sig) =
            abi.decode(validationData, (uint64, bytes32, uint256, bytes));
        if (expiry < block.timestamp) revert SignatureExpired();

        address returnedSigner = ECDSA.recover(_makeSignatureHash(uuid, expiry, salt), sig);
        return returnedSigner == signer;
    }

    /// @notice  Generates a hash for signing/verifying.
    ///
    /// @dev The message hash should be dervied by: `keccak256(abi.encode(0x1900, trustedSignerAddress, discountClaimerAddress, couponUui, claimsPerUuid, expiry, salt))`.
    ///     Compliant with EIP-191 for `Data for intended validator`: https://eips.ethereum.org/EIPS/eip-191#version-0x00 .
    ///
    /// @param couponUuid The Uuid of the coupon.
    /// @param expires The date of the signature expiry.
    /// @param salt Unique salt for this signature.
    ///
    /// @return The EIP-191 compliant signature hash.
    function _makeSignatureHash(bytes32 couponUuid, uint64 expires, uint256 salt) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(hex"1900", address(this), signer, couponUuid, expires, salt));
    }
}
