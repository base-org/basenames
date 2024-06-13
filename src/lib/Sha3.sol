//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

library Sha3 {
    // Hex encoding of "0123456789abcdef"
    bytes32 constant ALPHABET = 0x3031323334353637383961626364656600000000000000000000000000000000;

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
                addr := div(addr, 0x10)
                i := sub(i, 1)
                mstore8(i, byte(and(addr, 0xf), ALPHABET))
                addr := div(addr, 0x10)
            }

            ret := keccak256(0, 40)
        }
    }
}
