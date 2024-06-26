//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/// @title Sha3 Hex Encoding
///
/// @notice This method is copied from the ENS `ReverseRegistrar` contract. It's been moved to its own
///         lib for readability and testing purposes.
///         See: https://github.com/ensdomains/ens-contracts/blob/545a0104d0fbdd10865743e25729a921a76fd950/contracts/reverseRegistrar/ReverseRegistrar.sol#L164-L181
///
/// @author ENS (https://github.com/ensdomains/ens-contracts)
library Sha3 {
    /// @notice Hex encoding of "0123456789abcdef"
    bytes32 constant ALPHABET = 0x30_31_32_33_34_35_36_37_38_39_61_62_63_64_65_66_00000000000000000000000000000000;

    /// @notice Calculates the hash of a lower-case Ethereum address
    ///
    /// @param addr The address to hash
    ///
    /// @return ret The SHA3 hash of the lower-case hexadecimal encoding of the input address.
    function hexAddress(address addr) internal pure returns (bytes32 ret) {
        assembly {
            for { let i := 40 } i {} {
                i := sub(i, 1)
                mstore8(i, byte(and(addr, 0xf), ALPHABET))
                addr := shr(4, addr)
                i := sub(i, 1)
                mstore8(i, byte(and(addr, 0xf), ALPHABET))
                addr := shr(4, addr)
            }

            ret := keccak256(0, 40)
        }
    }
}
