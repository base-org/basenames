// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

library LibAddrResolver {
    bytes32 constant ADDR_RESOLVER_STORAGE_POS = keccak256("addr.resolver.storage.position");

    struct AddrResolverStorage {
        mapping(uint64 version => mapping(bytes32 node => mapping(uint256 cointype => bytes addr)))
            versionable_addresses;
    }

    function addrResolverStorage() internal pure returns (AddrResolverStorage storage $) {
        bytes32 pos = ADDR_RESOLVER_STORAGE_POS;
        assembly {
            $.slot := pos
        }
    }
}
