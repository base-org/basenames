// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import {Registry} from "src/L2/Registry.sol";
import {L1Resolver} from "src/L1/L1Resolver.sol";
import {SignatureVerifier} from "src/lib/SignatureVerifier.sol";
import "src/util/Constants.sol";
import "ens-contracts/utils/NameEncoder.sol";
import "solady/utils/LibString.sol";
import {ECDSA} from "lib/solady/src/utils/ECDSA.sol";
import {L2Resolver} from "src/L2/L2Resolver.sol";
import {ExtendedResolver} from "ens-contracts/resolvers/profiles/ExtendedResolver.sol";
import {AddrResolver} from "ens-contracts/resolvers/profiles/AddrResolver.sol";

interface Addr {
    function addr(bytes32) external;
}

address constant resolverAddr = 0xBD69dd64b94fe7435157F4851e4b4Aa3A0988c90; // l1 resolver

contract ResolveCallback is Script {
    function run() external view {
        address signer = 0xa412c16ECd2198A6aBce8235651E105684Fb77ed; // DEV signer

        (bytes memory dnsName, bytes32 node) = NameEncoder.dnsEncodeName("david.base.eth");
        console.log("The data arg for resolve call");
        bytes memory extraData = abi.encodeWithSelector(
            ExtendedResolver.resolve.selector, dnsName, abi.encodeWithSelector(Addr.addr.selector, node)
        );
        console.log("Extra data");
        console.logBytes(extraData);

        bytes memory callbackData =
            hex"00000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000066428903000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000020000000000000000000000000b18e4c959bccc8ef86d78dc297fb5efa99550d850000000000000000000000000000000000000000000000000000000000000041c147deedf5991f457236200665538c1f6f210a644839785aaf772ccecfc54f8318769d37a1ddf14be900b5799c88ca99d10fc5dc8049cb082e04289c3fd6d03f1b00000000000000000000000000000000000000000000000000000000000000";

        console.log("Calling verify");
        (address recoveredSigner, bytes memory response) = verify(extraData, callbackData);

        console.log("Recovered signer:");
        console.log(recoveredSigner);
        console.log("Expected signer");
        console.log(signer);
        console.log("Response");
        console.logBytes(response);
    }

    function verify(bytes memory request, bytes memory response) internal view returns (address, bytes memory) {
        (bytes memory result, uint64 expires, bytes memory sig) = abi.decode(response, (bytes, uint64, bytes));
        console.log("Result bytes");
        console.logBytes(result);
        console.log("expiry");
        console.log(expires);
        console.log("sig");
        console.logBytes(sig);
        address signer = ECDSA.recover(makeSignatureHash(resolverAddr, expires, request, result), sig);
        require(expires >= block.timestamp, "SignatureVerifier: Signature expired");
        return (signer, result);
    }

    function makeSignatureHash(address target, uint64 expires, bytes memory request, bytes memory result)
        internal
        view
        returns (bytes32)
    {
        bytes32 requestHash = keccak256(request);
        bytes32 resultHash = keccak256(result);
        console.log("Request hash");
        console.logBytes32(requestHash);
        console.log("ResultHash");
        console.logBytes32(resultHash);
        bytes memory word = abi.encodePacked(hex"1900", target, expires, requestHash, resultHash);
        console.log("Hash Preimage");
        console.logBytes(word);
        bytes32 hashed = keccak256(word);
        console.log("Hashed");
        console.logBytes32(hashed);
        return hashed;
    }
}
