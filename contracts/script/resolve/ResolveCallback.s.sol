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

contract ResolveCallback is Script {
    function run() external {
        // uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // vm.startBroadcast(deployerPrivateKey);

        /// L1 Resolver constructor data
        string memory url =
            "https://subdomain-did-api-dev.cbhq.net:8000/api/v1/domain/resolver/resolveDomain/{sender}/{data}"; //
        address[] memory signers = new address[](1);
        signers[0] = 0xa412c16ECd2198A6aBce8235651E105684Fb77ed; // DEV signer
        address resolverAddr = 0xBD69dd64b94fe7435157F4851e4b4Aa3A0988c90; // l1 resolver


        L1Resolver resolver = new L1Resolver(url, signers);
        (bytes memory dnsName ,bytes32 node) = NameEncoder.dnsEncodeName("david.base.eth");
        console.log("The data arg for resolve call");
        bytes memory extraData = abi.encodeWithSelector(
            ExtendedResolver.resolve.selector, 
            dnsName, 
            abi.encodeWithSelector(
                Addr.addr.selector, 
                node
            )
        );
        // resolver.resolve(dnsName, abi.encodeWithSelector(ExtendedResolver.resolve.selector, dnsName, abi.encodeWithSelector(Addr.addr.selector, node)));

        bytes memory callbackData = hex"000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000663e975500000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000414c7cdc56f1df622d8055acd4536555ca64cf470e6d8b9b13dc0a73fc3fe9b5282e2ffca4425f003290918b20ddc7208a13dc36324f3f34180f00f314081fbdc21b00000000000000000000000000000000000000000000000000000000000000";

        console.log("Calling verify");
        (address signer, bytes memory response) = verify(extraData, callbackData);

        // bytes memory response = resolver.resolveWithProof(callbackData, extraData);
        console.log(signer);
        console.logBytes(response);
        // vm.stopBroadcast();
    }

    function verify(bytes memory request, bytes memory response) internal view returns (address, bytes memory) {
        (bytes memory result, uint64 expires, bytes memory sig) = abi.decode(response, (bytes, uint64, bytes));
        console.logBytes(result);
        console.log(expires);
        console.logBytes(sig);
        address signer = ECDSA.recover(SignatureVerifier.makeSignatureHash(address(this), expires, request, result), sig);
        require(expires >= block.timestamp, "SignatureVerifier: Signature expired");
        return (signer, result);
    }
}
