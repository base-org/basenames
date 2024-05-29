// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract MockReverseRegistrar {
    bool public hasClaimed;

    function claim(address) external {
        hasClaimed = true;
    }
}
