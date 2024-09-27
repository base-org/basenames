// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Registry} from "src/L2/Registry.sol";
import {LibDiamond} from "../lib/LibDiamond.sol";

library LibResolverBase {
    bytes32 constant RESOLVER_BASE_STORAGE_POS = keccak256("resolver.base.storage.position");

    error NotAuthorized(bytes32 node, address caller);

    struct ResolverBaseStorage {
        Registry registry;
        mapping(address controller => bool approved) approvedControllers;        
        mapping(bytes32 node => uint64 version) recordVersions;
        mapping(address owner => (mapping(address operator => bool isApproved))) operators;
        mapping(address owner => mapping(bytes32 node => mapping(address delegate => bool isApproved))) tokenApprovals;
    }

    modifier isOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    modifier isAuthorized(bytes32 node, address caller) {
        if(!_isAuthorized(node, caller)) revert NotAuthorized(node, caller);
        _;
    }

    function _isAuthorized(bytes32 node, address caller) internal returns (bool) {
        ResolverBaseStorage storage s = resolverBaseStorage();
        if (s.approvedControllers[caller]) {
            return true;
        }
        address owner = s.registry.owner(node);
        return owner == msg.sender || s.operators[owner][caller] || s.tokenApprovals[owner][node][caller];
    }

    function resolverBaseStorage() internal pure returns (ResolverBaseStorage storage $) {
        bytes32 pos = RESOLVER_BASE_STORAGE_POS;
        assembly {
            $.slot := pos
        }
    }
}
