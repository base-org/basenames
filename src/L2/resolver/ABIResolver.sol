// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import {IABIResolver} from "ens-contracts/resolvers/profiles/IABIResolver.sol";

import {ResolverBase} from "./ResolverBase.sol";

abstract contract ABIResolver is IABIResolver, ResolverBase {
    struct ABIResolverStorage {
        mapping(uint64 version => mapping(bytes32 node => mapping(uint256 contentType => bytes data))) versionable_abis;
    }

    // keccak256(abi.encode(uint256(keccak256("abi.resolver.storage")) - 1)) & ~bytes32(uint256(0xff));
    bytes32 private constant ABI_RESOLVER_STORAGE = 0x76dc89e1c49d3cda8f11a131d381f3dbd0df1919a4e1a669330a2763d2821400;

    /**
     * Sets the ABI associated with an ENS node.
     * Nodes may have one ABI of each content type. To remove an ABI, set it to
     * the empty string.
     * @param node The node to update.
     * @param contentType The content type of the ABI
     * @param data The ABI data.
     */
    function setABI(bytes32 node, uint256 contentType, bytes calldata data) external virtual authorised(node) {
        // Content types must be powers of 2
        require(((contentType - 1) & contentType) == 0);

        _getABIResolverStorage().versionable_abis[_getResolverBaseStorage().recordVersions[node]][node][contentType] =
            data;
        emit ABIChanged(node, contentType);
    }

    /**
     * Returns the ABI associated with an ENS node.
     * Defined in EIP205.
     * @param node The ENS node to query
     * @param contentTypes A bitwise OR of the ABI formats accepted by the caller.
     * @return contentType The content type of the return value
     * @return data The ABI data
     */
    function ABI(bytes32 node, uint256 contentTypes) external view virtual override returns (uint256, bytes memory) {
        mapping(uint256 => bytes) storage abiset =
            _getABIResolverStorage().versionable_abis[_getResolverBaseStorage().recordVersions[node]][node];

        for (uint256 contentType = 1; contentType <= contentTypes; contentType <<= 1) {
            if ((contentType & contentTypes) != 0 && abiset[contentType].length > 0) {
                return (contentType, abiset[contentType]);
            }
        }

        return (0, bytes(""));
    }

    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
        return interfaceID == type(IABIResolver).interfaceId || super.supportsInterface(interfaceID);
    }

    function _getABIResolverStorage() internal pure returns (ABIResolverStorage storage $) {
        assembly {
            $.slot := ABI_RESOLVER_STORAGE
        }
    }
}
