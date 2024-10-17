// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IERC165} from "lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import {IInterfaceResolver} from "ens-contracts/resolvers/profiles/IInterfaceResolver.sol";

import {AddrResolver} from "./AddrResolver.sol";
import {ResolverBase} from "./ResolverBase.sol";

abstract contract InterfaceResolver is IInterfaceResolver, AddrResolver {
    struct InterfaceResolverStorage {
        mapping(uint64 version => mapping(bytes32 node => mapping(bytes4 interfaceId => address implemenentor)))
            versionable_interfaces;
    }

    // keccak256(abi.encode(uint256(keccak256("interface.resolver.storage")) - 1)) & ~bytes32(uint256(0xff));
    bytes32 constant INTERFACE_RESOLVER_STORAGE = 0x933ab330cd660334bb219a68b3bfaf86387ecd49e4e53a39e8310a5bd6910c00;

    /**
     * Sets an interface associated with a name.
     * Setting the address to 0 restores the default behaviour of querying the contract at `addr()` for interface support.
     * @param node The node to update.
     * @param interfaceID The EIP 165 interface ID.
     * @param implementer The address of a contract that implements this interface for this node.
     */
    function setInterface(bytes32 node, bytes4 interfaceID, address implementer) external virtual authorised(node) {
        _getInterfaceResolverStorage().versionable_interfaces[_getResolverBaseStorage().recordVersions[node]][node][interfaceID]
        = implementer;
        emit InterfaceChanged(node, interfaceID, implementer);
    }

    /**
     * Returns the address of a contract that implements the specified interface for this name.
     * If an implementer has not been set for this interfaceID and name, the resolver will query
     * the contract at `addr()`. If `addr()` is set, a contract exists at that address, and that
     * contract implements EIP165 and returns `true` for the specified interfaceID, its address
     * will be returned.
     * @param node The ENS node to query.
     * @param interfaceID The EIP 165 interface ID to check for.
     * @return The address that implements this interface, or 0 if the interface is unsupported.
     */
    function interfaceImplementer(bytes32 node, bytes4 interfaceID) external view virtual override returns (address) {
        address implementer = _getInterfaceResolverStorage().versionable_interfaces[_getResolverBaseStorage()
            .recordVersions[node]][node][interfaceID];
        if (implementer != address(0)) {
            return implementer;
        }

        address a = addr(node);
        if (a == address(0)) {
            return address(0);
        }

        (bool success, bytes memory returnData) =
            a.staticcall(abi.encodeWithSignature("supportsInterface(bytes4)", type(IERC165).interfaceId));
        if (!success || returnData.length < 32 || returnData[31] == 0) {
            // EIP 165 not supported by target
            return address(0);
        }

        (success, returnData) = a.staticcall(abi.encodeWithSignature("supportsInterface(bytes4)", interfaceID));
        if (!success || returnData.length < 32 || returnData[31] == 0) {
            // Specified interface not supported by target
            return address(0);
        }

        return a;
    }

    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
        return interfaceID == type(IInterfaceResolver).interfaceId || super.supportsInterface(interfaceID);
    }

    function _getInterfaceResolverStorage() internal pure returns (InterfaceResolverStorage storage $) {
        assembly {
            $.slot := INTERFACE_RESOLVER_STORAGE
        }
    }
}
