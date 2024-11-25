// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {UpgradeableL2ResolverBase} from "./UpgradeableL2ResolverBase.t.sol";
import {ResolverBase} from "src/L2/resolver/ResolverBase.sol";
import {DNSResolver} from "src/L2/resolver/DNSResolver.sol";
import {NameEncoder} from "ens-contracts/utils/NameEncoder.sol";

contract SetDNSRecords is UpgradeableL2ResolverBase {
    // Test data encoding taken from ENS text fixture:
    // https://github.com/ensdomains/ens-contracts/blob/staging/test/resolvers/TestPublicResolver.ts:fixtureWithDnsRecords()
    // Wire-encoded records:
    //      a.eth. 3600 IN A 1.2.3.4
    bytes arec = hex"016103657468000001000100000e10000401020304";
    //      b.eth. 3600 IN A 2.3.4.5
    bytes b1rec = hex"016203657468000001000100000e10000402030405";
    //      b.eth. 3600 IN A 3.4.5.6
    bytes b2rec = hex"016203657468000001000100000e10000403040506";
    //      eth. 86400 IN SOA ns1.ethdns.xyz. hostmaster.test.eth. 2018061501 15620 1800 1814400 14400
    bytes soarec =
        hex"03657468000006000100015180003a036e733106657468646e730378797a000a686f73746d6173746572057465737431036574680078492cbd00003d0400000708001baf8000003840";
    bytes dnsRecord = bytes.concat(arec, b1rec, b2rec, soarec);

    // DNS Record types: https://en.wikipedia.org/wiki/List_of_DNS_record_types
    uint16 constant A_RESOURCE = 1;
    uint16 constant SOA_RESOURCE = 6;

    function test_reverts_forUnauthorizedUser() public {
        vm.expectRevert(abi.encodeWithSelector(ResolverBase.NotAuthorized.selector, node, notUser));
        vm.prank(notUser);
        resolver.setDNSRecords(node, dnsRecord);
    }

    function test_setsTheDNSRecord() public {
        vm.prank(user);
        resolver.setDNSRecords(node, dnsRecord);

        (bytes memory aDnsName,) = NameEncoder.dnsEncodeName("a.eth");
        bytes memory arecRet = resolver.dnsRecord(node, keccak256(aDnsName), A_RESOURCE);
        assertEq(keccak256(arecRet), keccak256(arec));

        (bytes memory bDnsName,) = NameEncoder.dnsEncodeName("b.eth");
        bytes memory brecRet = resolver.dnsRecord(node, keccak256(bDnsName), A_RESOURCE);
        assertEq(keccak256(brecRet), keccak256(bytes.concat(b1rec, b2rec)));

        (bytes memory ethDnsName,) = NameEncoder.dnsEncodeName("eth");
        bytes memory soarecRet = resolver.dnsRecord(node, keccak256(ethDnsName), SOA_RESOURCE);
        assertEq(keccak256(soarecRet), keccak256(soarec));
    }
}