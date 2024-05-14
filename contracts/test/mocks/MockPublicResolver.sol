//SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

contract MockPublicResolver {
    mapping(bytes32 => address) addrs;

    constructor() {
        addrs[bytes32(uint256(1))] = address(1);
        addrs[bytes32(uint256(2))] = address(2);
    }

    function addr(bytes32 node) external view returns (address) {
        return addrs[node];
    }
}
