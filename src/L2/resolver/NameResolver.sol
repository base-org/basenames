// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {INameResolver} from "ens-contracts/resolvers/profiles/INameResolver.sol";

import {ResolverBase} from "./ResolverBase.sol";

abstract contract NameResolver is INameResolver, ResolverBase {
    struct NameResolverStorage {
        mapping(uint64 version => mapping(bytes32 node => string name)) versionable_names;
    }

    // keccak256(abi.encode(uint256(keccak256("name.resolver.storage")) - 1)) & ~bytes32(uint256(0xff));
    bytes32 constant NAME_RESOLVER_STORAGE = 0x23d7cb83bcf6186ccf590f4291f50469cd60b0ac3c413e76ea47a810986d8500;

    /**
     * Sets the name associated with an ENS node, for reverse records.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     */
    function setName(bytes32 node, string calldata newName) external virtual authorised(node) {
        _getNameResolver().versionable_names[_getResolverBaseStorage().recordVersions[node]][node] = newName;
        emit NameChanged(node, newName);
    }

    /**
     * Returns the name associated with an ENS node, for reverse records.
     * Defined in EIP181.
     * @param node The ENS node to query.
     * @return The associated name.
     */
    function name(bytes32 node) external view virtual override returns (string memory) {
        return _getNameResolver().versionable_names[_getResolverBaseStorage().recordVersions[node]][node];
    }

    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
        return interfaceID == type(INameResolver).interfaceId || super.supportsInterface(interfaceID);
    }

    function _getNameResolver() internal pure returns (NameResolverStorage storage $) {
        assembly {
            $.slot := NAME_RESOLVER_STORAGE
        }
    }
}
