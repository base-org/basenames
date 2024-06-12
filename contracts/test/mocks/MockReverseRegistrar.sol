// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract MockReverseRegistrar {
    struct MockReverseRecord {
        address addr;
        address owner;
        address resolver;
        string name;
    }

    mapping(address => bool) public hasClaimed;
    MockReverseRecord public record;

    function claim(address claimant) external {
        hasClaimed[claimant] = true;
    }

    function setNameForAddr(address addr, address owner, address resolver, string memory name)
        external
        returns (bytes32)
    {
        record = MockReverseRecord({addr: addr, owner: owner, resolver: resolver, name: name});
        hasClaimed[owner] = true;
        return bytes32(0);
    }
}
