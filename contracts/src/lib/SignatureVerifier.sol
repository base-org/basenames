// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ECDSA} from "lib/solady/src/utils/ECDSA.sol";

library SignatureVerifier {
    /**
     * @dev Generates a hash for signing/verifying.
     * @param target: The address the signature is for.
     * @param request: The original request that was sent.
     * @param result: The `result` field of the response (not including the signature part).
     */
    function makeSignatureHash(address target, uint64 expires, bytes memory request, bytes memory result) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(hex"1900", target, expires, keccak256(request), keccak256(result)));
    }

    /**
     * @dev Verifies a signed message returned from a callback.
     * @param request: The original request that was sent.
     * @param response: An ABI encoded tuple of `(bytes result, uint64 expires, bytes sig)`, where `result` is the data to return
     *        to the caller, and `sig` is the (r,s,v) encoded message signature.
     * @return signer: The address that signed this message.
     * @return result: The `result` decoded from `response`.
     */
    function verify(bytes calldata request, bytes calldata response) internal view returns(address, bytes memory) {
        (bytes memory result, uint64 expires, bytes memory sig) = abi.decode(response, (bytes, uint64, bytes));
        address signer = ECDSA.recover(makeSignatureHash(address(this), expires, request, result), sig);
        require(
            expires >= block.timestamp,
            "SignatureVerifier: Signature expired");
        return (signer, result);
    }
}