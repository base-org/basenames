// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Registry} from "src/L2/Registry.sol";
import {LibDiamond} from "./lib/LibDiamond.sol";
import {ResolverBase} from "./ResolverBase.sol";

abstract contract ResolverAuth {
    error NotAuthorized(bytes32 node, address caller);
    error OnlyOwner();

    modifier isOwner() {
        if(!ResolverBase._isContractOwner()) revert OnlyOwner();
        _;
    }

    modifier isAuthorized(bytes32 node) {
        if(!ResolverBase._isAuthorized(node, msg.sender)) revert NotAuthorized(node, msg.sender);
        _;
    }
}
