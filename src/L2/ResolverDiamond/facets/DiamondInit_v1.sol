// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Registry} from "src/L2/Registry.sol";

import {LibResolverBase} from "../storage/LibResolverBase.sol";

contract DiamondInit_v1 {
    function initialize(Registry registry, address[] calldata controllers) external {
        LibResolverBase.ResolverBaseStorage storage s = LibResolverBase.resolverBaseStorage();
        s.registry = registry;
        for (uint256 i; i < controllers.length; i++) {
            s.approvedControllers[controllers[i]] = true;
        }
    }
}
