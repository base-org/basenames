//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

library Sha3 {
    // Hex encoding of "0123456789abcdef"
    bytes32 constant ALPHABET = 0x30_31_32_33_34_35_36_37_38_39_61_62_63_64_65_66_00000000000000000000000000000000;

    /**
     * @dev An optimised function to compute the sha3 of the lower-case
     *      hexadecimal representation of an Ethereum address.
     * @param addr The address to hash
     * @return ret The SHA3 hash of the lower-case hexadecimal encoding of the
     *         input address.
     */
    function hexAddress(address addr) internal pure returns (bytes32 ret) {
        assembly {
            for { let i := 40 } gt(i, 0) {} {
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
