//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {BaseRegistrar} from "src/L2/BaseRegistrar.sol";
import {BaseRegistrarBase} from "./BaseRegistrarBase.t.sol";
import {ERC721} from "lib/solady/src/tokens/ERC721.sol";
import {ENS} from "ens-contracts/registry/ENS.sol";
import {BASE_ETH_NODE, GRACE_PERIOD} from "src/util/Constants.sol";

contract RegisterWithRecord is BaseRegistrarBase {
    function test_reverts_whenTheRegistrarIsNotLive() public {
        vm.prank(address(baseRegistrar));
        registry.setOwner(BASE_ETH_NODE, owner);
        vm.expectRevert(BaseRegistrar.RegistrarNotLive.selector);
        baseRegistrar.registerWithRecord(id, user, duration, resolver, ttl);
    }

    function test_reverts_whenCalledByNonController(address caller) public {
        vm.prank(caller);
        vm.expectRevert(BaseRegistrar.OnlyController.selector);
        baseRegistrar.registerWithRecord(id, user, duration, resolver, ttl);
    }

    function test_successfullyRegisters() public {
        _registrationSetup();

        vm.expectEmit(address(baseRegistrar));
        emit ERC721.Transfer(address(0), user, id);
        vm.expectEmit(address(registry));
        emit ENS.NewOwner(BASE_ETH_NODE, bytes32(id), user);
        vm.expectEmit(address(baseRegistrar));
        emit BaseRegistrar.NameRegisteredWithRecord(id, user, duration + blockTimestamp, resolver, ttl);

        vm.warp(blockTimestamp);
        vm.prank(controller);
        uint256 expires = baseRegistrar.registerWithRecord(id, user, duration, resolver, ttl);

        address ownerOfToken = baseRegistrar.ownerOf(id);
        assertEq(ownerOfToken, user);
        assertEq(baseRegistrar.nameExpires(id), expires);
        assertEq(registry.resolver(node), resolver);
        assertEq(registry.ttl(node), ttl);
    }

    function test_successfullyRegisters_afterExpiry(address newOwner) public {
        vm.assume(newOwner != user && newOwner != address(0));
        _registrationSetup();
        _registerName(label, user, duration);

        uint256 newBlockTimestamp = blockTimestamp + duration + GRACE_PERIOD + 1;
        vm.expectEmit(address(baseRegistrar));
        emit ERC721.Transfer(user, address(0), id); // on _burn(id)
        vm.expectEmit(address(baseRegistrar));
        emit ERC721.Transfer(address(0), newOwner, id);
        vm.expectEmit(address(registry));
        emit ENS.NewOwner(BASE_ETH_NODE, bytes32(id), newOwner);
        vm.expectEmit(address(baseRegistrar));
        emit BaseRegistrar.NameRegisteredWithRecord(id, newOwner, duration + newBlockTimestamp, resolver, ttl);

        vm.warp(newBlockTimestamp);
        vm.prank(controller);
        uint256 expires = baseRegistrar.registerWithRecord(id, newOwner, duration, resolver, ttl);

        address ownerOfToken = baseRegistrar.ownerOf(id);
        assertEq(ownerOfToken, newOwner);
        assertEq(baseRegistrar.nameExpires(id), expires);
        assertEq(registry.resolver(node), resolver);
        assertEq(registry.ttl(node), ttl);
    }

    function test_reverts_ifTheNameIsNotAvailable(address newOwner) public {
        vm.assume(newOwner != user);
        _registrationSetup();
        _registerName(label, user, duration);

        vm.expectRevert(abi.encodeWithSelector(BaseRegistrar.NotAvailable.selector, id));
        vm.prank(controller);
        baseRegistrar.registerWithRecord(id, user, duration, resolver, ttl);
    }

    function test_reverts_ifTheNameIsNotAvailable_duringGracePeriod(address newOwner) public {
        vm.assume(newOwner != user);
        _registrationSetup();
        _registerName(label, user, duration);

        vm.expectRevert(abi.encodeWithSelector(BaseRegistrar.NotAvailable.selector, id));
        vm.warp(blockTimestamp + duration + GRACE_PERIOD - 1);
        vm.prank(controller);
        baseRegistrar.registerWithRecord(id, user, duration, resolver, ttl);
    }
}
