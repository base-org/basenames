//SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {L1ResolverTestBase} from "./L1ResolverBase.t.sol";

import {L1Resolver} from "src/L1/L1Resolver.sol";
import {Ownable} from "solady/auth/Ownable.sol";

contract SupportsInterface is L1ResolverTestBase {
    function test_supportsInterface() public view {
        assertTrue(resolver.supportsInterface(bytes4(0x9061b923))); // https://docs.ens.domains/ensip/10
    }
}
