//SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {L1ResolverTestBase} from "./L1ResolverBase.t.sol";

import {L1Resolver} from "src/L1/L1Resolver.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {NameEncoder} from "ens-contracts/utils/NameEncoder.sol";
import {PublicResolver} from "ens-contracts/resolvers/PublicResolver.sol";

contract L1ResolverTest is L1ResolverTestBase {

    function test_constructor_setsURL() public view {
        assertTrue(keccak256(bytes(resolver.url())) == keccak256(bytes(URL)));
        address[] memory signers = new address[](1);
        signers[0] = signer;        
    }

    function test_constructor_setsSigner() public view {
        assertTrue(resolver.signers(signer));
    }

    function test_constructor_setsOwner() public view {
        assertTrue(resolver.owner() == owner);
    }

    function test_constructor_setsRootResolver() public view {
        assertTrue(resolver.rootResolver() == address(rootResolver));
    }
}