//SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {L1Resolver} from "src/L1/L1Resolver.sol";
import {NameEncoder} from "ens-contracts/utils/NameEncoder.sol";
import {MockPublicResolver} from "src/mocks/MockPublicResolver.sol";

contract L1ResolverTestBase is Test {
    L1Resolver public resolver;
    MockPublicResolver public rootResolver;

    function setUp() public {
        address[] memory _signer = new address[](1);
        _signer[0] = makeAddr("0xal1ce");
        address owner = makeAddr("0x1");
        rootResolver = new MockPublicResolver();
        
        resolver = new L1Resolver(
            "",
            _signer,
            owner,
            address(rootResolver)
        );
    }
}