// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import {IAddrResolver} from "ens-contracts/resolvers/profiles/IAddrResolver.sol";
import {IAddressResolver} from "ens-contracts/resolvers/profiles/IAddressResolver.sol";

import {ResolverBase} from "./ResolverBase.sol";

abstract contract AddrResolver is IAddrResolver, IAddressResolver, ResolverBase {
    struct AddrResolverStorage {
        mapping(uint64 version => mapping(bytes32 node => mapping(uint256 cointype => bytes addr)))
            versionable_addresses;
    }

    // keccak256(abi.encode(uint256(keccak256("addr.resolver.storage")) - 1)) & ~bytes32(uint256(0xff));
    bytes32 constant ADDR_RESOLVER_STORAGE = 0x1871a91a9a944f867849820431bb11c2d1625edae573523bceb5b38b8b8a7500;

    uint256 private constant COIN_TYPE_ETH = 60;

    /**
     * Sets the address associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param a The address to set.
     */
    function setAddr(bytes32 node, address a) external virtual authorised(node) {
        setAddr(node, COIN_TYPE_ETH, addressToBytes(a));
    }

    /**
     * Returns the address associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated address.
     */
    function addr(bytes32 node) public view virtual override returns (address payable) {
        bytes memory a = addr(node, COIN_TYPE_ETH);
        if (a.length == 0) {
            return payable(0);
        }
        return bytesToAddress(a);
    }

    function setAddr(bytes32 node, uint256 coinType, bytes memory a) public virtual authorised(node) {
        emit AddressChanged(node, coinType, a);
        if (coinType == COIN_TYPE_ETH) {
            emit AddrChanged(node, bytesToAddress(a));
        }
        _getAddrResolverStorage().versionable_addresses[_getResolverBaseStorage().recordVersions[node]][node][coinType]
        = a;
    }

    function addr(bytes32 node, uint256 coinType) public view virtual override returns (bytes memory) {
        return _getAddrResolverStorage().versionable_addresses[_getResolverBaseStorage().recordVersions[node]][node][coinType];
    }

    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
        return interfaceID == type(IAddrResolver).interfaceId || interfaceID == type(IAddressResolver).interfaceId
            || super.supportsInterface(interfaceID);
    }

    function bytesToAddress(bytes memory b) internal pure returns (address payable a) {
        require(b.length == 20);
        assembly {
            a := div(mload(add(b, 32)), exp(256, 12))
        }
    }

    function addressToBytes(address a) internal pure returns (bytes memory b) {
        b = new bytes(20);
        assembly {
            mstore(add(b, 32), mul(a, exp(256, 12)))
        }
    }

    function _getAddrResolverStorage() internal pure returns (AddrResolverStorage storage $) {
        assembly {
            $.slot := ADDR_RESOLVER_STORAGE
        }
    }
}
