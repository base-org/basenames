// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import {IPubkeyResolver} from "ens-contracts/resolvers/profiles/IPubkeyResolver.sol";

import {ResolverBase} from "./ResolverBase.sol";

abstract contract PubkeyResolver is IPubkeyResolver, ResolverBase {
    struct PublicKey {
        bytes32 x;
        bytes32 y;
    }

    struct PubkeyResolverStorage {
        mapping(uint64 version => mapping(bytes32 node => PublicKey pubkey)) versionable_pubkeys;
    }

    // keccak256(abi.encode(uint256(keccak256("pubkey.resolver.storage")) - 1)) & ~bytes32(uint256(0xff));
    bytes32 constant PUBKEY_RESOLVER_STORAGE = 0x59a318c6a4da81295c2a32b42a02c3db057bb9422e2eb1f6e516ee3694b1ef00;

    /**
     * Sets the SECP256k1 public key associated with an ENS node.
     * @param node The ENS node to query
     * @param x the X coordinate of the curve point for the public key.
     * @param y the Y coordinate of the curve point for the public key.
     */
    function setPubkey(bytes32 node, bytes32 x, bytes32 y) external virtual authorised(node) {
        _getPubkeyResolverStorage().versionable_pubkeys[_getResolverBaseStorage().recordVersions[node]][node] =
            PublicKey(x, y);
        emit PubkeyChanged(node, x, y);
    }

    /**
     * Returns the SECP256k1 public key associated with an ENS node.
     * Defined in EIP 619.
     * @param node The ENS node to query
     * @return x The X coordinate of the curve point for the public key.
     * @return y The Y coordinate of the curve point for the public key.
     */
    function pubkey(bytes32 node) external view virtual override returns (bytes32 x, bytes32 y) {
        uint64 currentRecordVersion = _getResolverBaseStorage().recordVersions[node];
        PubkeyResolverStorage storage $ = _getPubkeyResolverStorage();
        return
            ($.versionable_pubkeys[currentRecordVersion][node].x, $.versionable_pubkeys[currentRecordVersion][node].y);
    }

    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
        return interfaceID == type(IPubkeyResolver).interfaceId || super.supportsInterface(interfaceID);
    }

    function _getPubkeyResolverStorage() internal pure returns (PubkeyResolverStorage storage $) {
        assembly {
            $.slot := PUBKEY_RESOLVER_STORAGE
        }
    }
}
