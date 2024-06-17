//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {AttestationAccessControl} from "verifications/abstracts/AttestationAccessControl.sol";
import {AttestationVerifier} from "verifications/libraries/AttestationVerifier.sol";
import {ECDSA} from "solady/utils/ECDSA.sol";
import {IAttestationIndexer} from "verifications/interfaces/IAttestationIndexer.sol";
import {Ownable} from "solady/auth/Ownable.sol";

import {IDiscountValidator} from "src/L2/interface/IDiscountValidator.sol";

/// @title Discount Validator for: Coinbase Verified Wallets
///
/// @notice Implements a two step validation schema for Coinbase Verified Wallets
///         1. Verify that the wallet has an active Coinbase Verified Account attestation with EAS
///         2. Signature verification to valiate signatures from the Coinbase sybil resistance service.
///         https://github.com/coinbase/verifications  
///
/// @author Coinbase (https://github.com/base-org/usernames)
contract VerifiedAccountValidator is Ownable, AttestationAccessControl, IDiscountValidator {
    /// @dev The attestation service signer. 
    address signer;

    /// @dev The EAS schema id for Coinbase Verified Wallets.
    bytes32 schemaID;

    /// @notice Thrown when the address for the claimer recovered from `validationData` does not match the address passed
    ///         to the validator. 
    ///
    /// @param expectedClaimer The address packed in `validationData` as the expected claimer.
    /// @param claimer The address that is calling the discounted registration.
    error ClaimerAddressMismatch(address expectedClaimer, address claimer);

    /// @notice Thrown when the signature expiry date >= block.timestamp.
    error SignatureExpired();

    /// @notice Verified Account Validator constructor
    ///
    /// @param owner_ The permissioned `owner` in the `Ownable` context.
    /// @param signer_ The off-chain signer of the Coinbase sybil resistance service.
    /// @param schemaID_ The EAS schema id associated with verified accounts.
    /// @param indexer_ The address of the Coinbase attestation indexer. 
    constructor(address owner_, address signer_, bytes32 schemaID_, address indexer_) {
        _initializeOwner(owner_);
        signer = signer_;
        schemaID = schemaID_;
        _setIndexer(IAttestationIndexer(indexer_));
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
    /// @param claimer the discount claimer's address.
    /// @param validationData opaque bytes for performing the validation.
    ///
    /// @return `true` if the validation data provided is determined to be valid for the specified claimer, else `false`.
    function isValidDiscountRegistration(address claimer, bytes calldata validationData) external view returns (bool) {

        AttestationVerifier.verifyAttestation(_getAttestation(claimer, schemaID));

        (address expectedClaimer, uint64 expires, bytes memory sig) = abi.decode(validationData, (address, uint64, bytes));
        if (expectedClaimer != claimer) revert ClaimerAddressMismatch(expectedClaimer, claimer);
        if (expires < block.timestamp) revert SignatureExpired();
        
        address recoveredSigner = ECDSA.recover(_makeSignatureHash(claimer, expires), sig);
        return (recoveredSigner == signer);
    }

    /// @notice  Generates a hash for signing/verifying.
    ///
    /// @dev The message hash should be dervied by: `keccak256(abi.encode(0x1900, trustedSignerAddress, discountClaimerAddress, expiry))`. 
    ///
    /// @param claimer The address of the claimer.
    /// @param expires The date of signature expiry.
    function _makeSignatureHash(address claimer, uint64 expires)
        internal
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(hex"1900", signer, claimer, expires));
    }
}
