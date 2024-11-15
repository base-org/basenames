// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {UpgradeableL2ResolverBase} from "./UpgradeableL2ResolverBase.t.sol";
import {ResolverBase} from "src/L2/resolver/ResolverBase.sol";
import {DNSResolver} from "src/L2/resolver/DNSResolver.sol";

contract SetDNSRecords is UpgradeableL2ResolverBase {
    bytes dnsRecord = hex"";

    function test_reverts_forUnauthorizedUser() public {
        vm.expectRevert(abi.encodeWithSelector(ResolverBase.NotAuthorized.selector, node, notUser));
        vm.prank(notUser);
        resolver.setDNSRecords(node, dnsRecord);
    }

    // @todo find and integrate a tool to help wire-encode DNS messages for this resolver
    // function test_setsTheDNSRecord() public {
    //     vm.prank(user);
    //     resolver.setDNSRecords(node, dnsRecord);

    // }
}
