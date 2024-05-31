//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {NameResolver} from "ens-contracts/resolvers/profiles/NameResolver.sol";

contract MockNameResolver is NameResolver {
    function isAuthorised(bytes32) internal pure override returns (bool) {
        return true;
    }
}
