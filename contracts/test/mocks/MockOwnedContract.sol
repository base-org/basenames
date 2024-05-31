//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Ownable} from "solady/auth/Ownable.sol";

contract MockOwnedContract is Ownable {
    constructor(address owner) {
        _initializeOwner(owner);
    }
}
