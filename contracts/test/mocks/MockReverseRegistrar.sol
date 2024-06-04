// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract MockReverseRegistrar {
    struct MockReverseRecord {
        address addr;
        address owner;
        address resolver;
        string name;
    }

    bool public hasClaimed;
    MockReverseRecord public record;

    function claim(address) external {
        hasClaimed = true;
    }

    function setNameForAddr(address addr, address owner, address resolver, string memory name)
        external
        returns (bytes32)
    {
        record = MockReverseRecord({addr: addr, owner: owner, resolver: resolver, name: name});
        return bytes32(0);
    }
}
