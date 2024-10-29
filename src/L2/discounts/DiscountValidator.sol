// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/// @title Discount Validator Interface
///
/// @notice Common interface which all Discount Validators must implement.
///         The logic specific to each integration must ultimately be consumable as the `bool` returned from
///         `isValidDiscountRegistration`. Then, upon registration, the integrator should call `validateDiscountRegistration`
///         allowing discount-specific state writes to occur. 
abstract contract DiscountValidator {
    /// @notice Thrown when the specified discount's validator does not accept the discount for the sender.
    ///
    /// @param claimer The discount being accessed.
    /// @param data The associated `validationData`.
    error InvalidDiscount(address claimer, bytes data);

    /// @notice Required implementation for compatibility with IDiscountValidator.
    ///
    /// @dev Each implementation will have unique requirements for the data necessary to perform
    ///     a meaningul validation. Implementations must describe here how to pack relevant `validationData`.
    ///     Ex: `bytes validationData = abi.encode(bytes32 key, bytes32[] proof)`
    ///
    /// @param claimer the discount claimer's address.
    /// @param validationData opaque bytes for performing the validation.
    ///
    /// @return `true` if the validation data provided is determined to be valid for the specified claimer, else `false`.
    function isValidDiscountRegistration(address claimer, bytes calldata validationData) public virtual view returns (bool);

    function validateDiscountRegistration(address claimer, bytes calldata validationData) external virtual view {
        if(!isValidDiscountRegistration(claimer, validationData)) revert InvalidDiscount(claimer, validationData);
    }
}
