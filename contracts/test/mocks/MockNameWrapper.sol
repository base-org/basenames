// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract MockNameWrapper {
    mapping(uint256 => uint256) expiries;
    mapping(string => bool) public hasRegistered;

    function setExpiry(uint256 id, uint256 expiry) external {
        expiries[id] = expiry;
    }

    function renew(uint256 id, uint256 duration) external returns (uint256) {
        expiries[id] += duration;
        return expiries[id];
    }

    function registerAndWrapETH2LD(string memory name, address, uint256 duration, address, uint16)
        external
        returns (uint256)
    {
        hasRegistered[name] = true;
        return block.timestamp + duration;
    }
}
