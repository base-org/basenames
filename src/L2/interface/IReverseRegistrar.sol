// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IReverseRegistrar {
    function claim(address claimant) external;

    function setNameForAddr(address addr, address owner, address resolver, string memory name)
        external
        returns (bytes32);
}
