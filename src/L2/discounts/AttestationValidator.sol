//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ECDSA} from "solady/utils/ECDSA.sol";
import {Ownable} from "solady/auth/Ownable.sol";

import {IDiscountValidator} from "src/L2/interface/IDiscountValidator.sol";

/// @title Discount Validator for: Coinbase supported EAS
///
/// @notice Implements signature verification to valiate signatures from the Coinbase attestation sybil resistance service.  
///
/// @author Coinbase
contract AttestationValidator is Ownable, IDiscountValidator {
    /// @dev The attestation service signer. 
    address signer;

    /// @notice Thrown when the address for the claimer recovered from `validationData` does not match the address passed
    ///         to the validator. 
    ///
    /// @param expectedClaimer The address packed in `validationData` as the expected claimer.
    /// @param claimer The address that is calling the discounted registration.
    error ClaimerAddressMismatch(address expectedClaimer, address claimer);

    /// @notice Thrown when the signature expiry date > block.timestamp.
    error SignatureExpired();

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
    /// @dev The proof data must be encoded as `abi.encode(discountClaimerAddress, expiry, signature_bytes)`.
    ///
    /// @param claimer the discount claimer's address.
    /// @param validationData opaque bytes for performing the validation.
    ///
    /// @return `true` if the validation data provided is determined to be valid for the specified claimer, else `false`.
    function isValidDiscountRegistration(address claimer, bytes calldata validationData) external view returns (bool) {
        (address expectedClaimer, uint64 expires, bytes memory sig) = abi.decode(validationData, (address, uint64, bytes));
        if (expectedClaimer != claimer) revert ClaimerAddressMismatch(expectedClaimer, claimer);
        if (expires < block.timestamp) revert SignatureExpired();
        
        address recoveredSigner = ECDSA.recover(makeSignatureHash(claimer, expires), sig);
        return (recoveredSigner == signer);
    }

    /// @notice  Generates a hash for signing/verifying.
    ///
    /// @dev The message hash should be dervied by: `keccak256(abi.encode(0x1900, trustedSignerAddress, discountClaimerAddress, expiry))`. 
    ///
    /// @param claimer The address of the claimer.
    /// @param expires The date of signature expiry.
    function makeSignatureHash(address claimer, uint64 expires)
        internal
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(hex"1900", signer, claimer, expires));
    }
}
