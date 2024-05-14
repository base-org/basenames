//SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {L1Resolver} from "src/L1/L1Resolver.sol";
import {MockPublicResolver} from "test/mocks/MockPublicResolver.sol";

contract L1ResolverTestBase is Test {
    L1Resolver public resolver;
    MockPublicResolver public rootResolver;
    string constant URL = "TEST_URL";
    address public signer = makeAddr("0xal1ce");
    address public owner = makeAddr("0x1");

    function setUp() public {
        address[] memory signers = new address[](1);
        signers[0] = signer;
        rootResolver = new MockPublicResolver();
        vm.expectEmit();
        emit L1Resolver.NewSigners(signers);
        resolver = new L1Resolver(URL, signers, owner, address(rootResolver));
    }

    function test_constructor() public {
        address[] memory signers_ = new address[](1);
        signers_[0] = signer;
        emit L1Resolver.NewSigners(signers_);

        resolver = new L1Resolver(URL, signers_, owner, address(rootResolver));
        assertTrue(keccak256(bytes(resolver.url())) == keccak256(bytes(URL)));
        assertTrue(resolver.signers(signer));
        assertTrue(resolver.owner() == owner);
        assertTrue(resolver.rootResolver() == address(rootResolver));
    }
}
