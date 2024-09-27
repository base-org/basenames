// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IVersionableResolver {
    function recordVersions(bytes32 node) external view returns (uint64);
}
