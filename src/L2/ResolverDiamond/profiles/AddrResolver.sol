// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import {ResolverAuth} from "../ResolverAuth.sol";
import {LibResolverBase} from "../storage/LibResolverBase.sol";
import {LibAddrResolver} from "../storage/LibAddrResolver.sol";

abstract contract AddrResolver is ResolverAuth {
    event AddrChanged(bytes32 indexed node, address a);
    event AddressChanged(bytes32 indexed node, uint256 coinType, bytes newAddress);

    uint256 private constant COIN_TYPE_ETH = 60;

    /**
     * Sets the address associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param a The address to set.
     */
    function setAddr(bytes32 node, address a) external virtual isAuthorized(node) {
        setAddr(node, COIN_TYPE_ETH, addressToBytes(a));
    }

    /**
     * Returns the address associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated address.
     */
    function addr(bytes32 node) public view virtual returns (address payable) {
        bytes memory a = addr(node, COIN_TYPE_ETH);
        if (a.length == 0) {
            return payable(0);
        }
        return bytesToAddress(a);
    }

    function setAddr(bytes32 node, uint256 coinType, bytes memory a) public virtual isAuthorized(node) {
        emit AddressChanged(node, coinType, a);
        if (coinType == COIN_TYPE_ETH) {
            emit AddrChanged(node, bytesToAddress(a));
        }
        LibResolverBase.ResolverBaseStorage storage bs = LibResolverBase.resolverBaseStorage();
        LibAddrResolver.AddrResolverStorage storage s = LibAddrResolver.addrResolverStorage();
        s.versionable_addresses[bs.recordVersions[node]][node][coinType] = a;
    }

    function addr(bytes32 node, uint256 coinType) public view virtual returns (bytes memory) {
        LibResolverBase.ResolverBaseStorage storage bs = LibResolverBase.resolverBaseStorage();
        LibAddrResolver.AddrResolverStorage storage s = LibAddrResolver.addrResolverStorage();
        return s.versionable_addresses[bs.recordVersions[node]][node][coinType];
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
}
