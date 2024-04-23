//SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {L1Resolver} from "src/L1/L1Resolver.sol";

contract L1ResolverTest is Test {

    L1Resolver public resolver;

    function setUp() public {
        address[] memory _signer = new address[](1);
        _signer[0] = makeAddr("0xal1ce");
        resolver = new L1Resolver(
            "",
            _signer
        );
    }

    function test_supportsInterface() public view {
        assertTrue(resolver.supportsInterface(bytes4(0x9061b923))); // https://docs.ens.domains/ensip/10
    }
}