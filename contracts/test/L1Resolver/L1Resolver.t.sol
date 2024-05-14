//SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {L1ResolverTestBase} from "./L1ResolverBase.t.sol";

import {L1Resolver} from "src/L1/L1Resolver.sol";
import {NameEncoder} from "ens-contracts/utils/NameEncoder.sol";
import {PublicResolver} from "ens-contracts/resolvers/PublicResolver.sol";

contract L1ResolverTest is L1ResolverTestBase {

    function test_supportsInterface() public view {
        assertTrue(resolver.supportsInterface(bytes4(0x9061b923))); // https://docs.ens.domains/ensip/10
    }

    function test_generateNames() public view {
        (bytes memory dnsName, bytes32 node) = NameEncoder.dnsEncodeName("base.eth");
        console.logBytes(dnsName);
        console.logBytes32(node);
    }
}