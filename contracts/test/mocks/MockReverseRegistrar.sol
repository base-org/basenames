// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract MockReversRegistrar {
    bool public hasClaimed;

    function claim(address) external {
        hasClaimed = true;
    }
}
