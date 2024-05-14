//SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {L1ResolverTestBase} from "./L1ResolverBase.t.sol";

import {L1Resolver} from "src/L1/L1Resolver.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {NameEncoder} from "ens-contracts/utils/NameEncoder.sol";
import {PublicResolver} from "ens-contracts/resolvers/PublicResolver.sol";

contract L1ResolverTest is L1ResolverTestBase {

    function test_supportsInterface() public view {
        assertTrue(resolver.supportsInterface(bytes4(0x9061b923))); // https://docs.ens.domains/ensip/10
    }

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

    function test_setUrl(string memory newUrl) public {
        vm.prank(makeAddr("0x2"));
        vm.expectRevert(abi.encodeWithSelector(Ownable.Unauthorized.selector));
        resolver.setUrl(newUrl);

        vm.prank(owner);
        vm.expectEmit();
        emit L1Resolver.NewUrl(newUrl);
        resolver.setUrl(newUrl);
    }

    function test_addSigners(address[] calldata _signers) public {
        vm.assume(_signers.length < 10);
        vm.prank(makeAddr("0x2"));
        vm.expectRevert(abi.encodeWithSelector(Ownable.Unauthorized.selector));
        resolver.addSigners(_signers);

        vm.prank(owner);
        vm.expectEmit();
        emit L1Resolver.NewSigners(_signers);
        resolver.addSigners(_signers);
    }

    function test_removeSigner() public {
        vm.prank(makeAddr("0x2"));
        vm.expectRevert(abi.encodeWithSelector(Ownable.Unauthorized.selector));
        resolver.removeSigner(signer);

        assertTrue(resolver.signers(signer));
        vm.prank(owner);
        vm.expectEmit();
        emit L1Resolver.RemovedSigner(signer);
        resolver.removeSigner(signer);
        assertFalse(resolver.signers(signer));
    }

    function test_setRootResolver(address newResolver) public {
        vm.prank(makeAddr("0x2"));
        vm.expectRevert(abi.encodeWithSelector(Ownable.Unauthorized.selector));
        resolver.setRootResolver(newResolver);

        vm.prank(owner);
        vm.expectEmit();
        emit L1Resolver.NewRootResolver(newResolver);
        resolver.setRootResolver(newResolver);
    }
}