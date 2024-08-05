//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {L1Resolver} from "src/L1/L1Resolver.sol";
import {ENS} from "ens-contracts/registry/ENS.sol";
import {IExtendedResolver} from "ens-contracts/resolvers/profiles/IExtendedResolver.sol";
import "src/util/Constants.sol";
import "ens-contracts/resolvers/profiles/IAddrResolver.sol";

contract L1ResolverMainnet is Test {
    address signer = 0x14536667Cd30e52C0b458BaACcB9faDA7046E056;
    ENS public ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
    address rootResolver = 0x4976fb03C32e5B8cfe2b6cCB31c09Ba78EBaBa41;
    address addrRoot;
    address l1resolver;

    string constant URL = "TEST_URL";

    function setUp() public {
        uint256 forkId = vm.createFork("https://eth.llamarpc.com");
        vm.selectFork(forkId);

        address[] memory signers = new address[](1);
        signers[0] = signer;
        l1resolver = address(new L1Resolver(URL, signers, signer, rootResolver));

        vm.startPrank(signer);
        ens.setResolver(BASE_ETH_NODE, l1resolver);
        assertEq(ens.resolver(BASE_ETH_NODE), l1resolver);
        addrRoot = IAddrResolver(rootResolver).addr(BASE_ETH_NODE);
    }

    function test_resolves_addr() public view {
        address resolvedAddress = IAddrResolver(l1resolver).addr(BASE_ETH_NODE);
        assertEq(resolvedAddress, addrRoot);
    }

    function test_resolves_resolve() public view {
        bytes memory data = abi.encodeWithSelector(IAddrResolver.addr.selector, BASE_ETH_NODE);
        bytes memory response = IExtendedResolver(l1resolver).resolve(BASE_ETH_NAME, data);
        (address resolvedAddress) = abi.decode(response, (address));
        assertEq(resolvedAddress, addrRoot);
    }
}
