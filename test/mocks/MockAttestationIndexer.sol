//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract MockAttestationIndexer {
    bytes32 uid;

    constructor(bytes32 uid_) {
        uid = uid_;
    }

    function getAttestationUid(address, bytes32) external view returns (bytes32) {
        return uid;
    }
}
