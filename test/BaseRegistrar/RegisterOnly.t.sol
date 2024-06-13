//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {BaseRegistrar} from "src/L2/BaseRegistrar.sol";
import {BaseRegistrarBase} from "./BaseRegistrarBase.t.sol";
import {ERC721} from "lib/solady/src/tokens/ERC721.sol";
import {BASE_ETH_NODE, GRACE_PERIOD} from "src/util/Constants.sol";
import {NameEncoder} from "ens-contracts/utils/NameEncoder.sol";

contract RegisterOnly is BaseRegistrarBase {
    function test_reverts_whenTheRegistrarIsNotLive() public {
        vm.prank(address(baseRegistrar));
        registry.setOwner(BASE_ETH_NODE, owner);
        vm.expectRevert(BaseRegistrar.RegistrarNotLive.selector);
        baseRegistrar.registerOnly(id, user, duration);
    }

    function test_reverts_whenCalledByNonController(address caller) public {
        vm.prank(caller);
        vm.expectRevert(BaseRegistrar.OnlyController.selector);
        baseRegistrar.registerOnly(id, user, duration);
    }

    function test_successfullyRegistersOnly() public {
        _registrationSetup();

        vm.expectEmit(address(baseRegistrar));
        emit ERC721.Transfer(address(0), user, id);
        vm.expectEmit(address(baseRegistrar));
        emit BaseRegistrar.NameRegistered(id, user, duration + blockTimestamp);

        vm.warp(blockTimestamp);
        vm.prank(controller);
        uint256 expires = baseRegistrar.registerOnly(id, user, duration);

        address ownerOfToken = baseRegistrar.ownerOf(id);
        assertTrue(ownerOfToken == user);
        assertTrue(baseRegistrar.nameExpires(id) == expires);
    }

    function test_successfullyRegisters_afterExpiry(address newOwner) public {
        vm.assume(newOwner != user && newOwner != address(0));
        _registrationSetup();

        vm.warp(blockTimestamp);
        vm.prank(controller);
        baseRegistrar.registerOnly(id, user, duration);

        uint256 newBlockTimestamp = blockTimestamp + duration + GRACE_PERIOD + 1;
        vm.expectEmit(address(baseRegistrar));
        emit ERC721.Transfer(user, address(0), id); // on _burn(id)
        vm.expectEmit(address(baseRegistrar));
        emit ERC721.Transfer(address(0), newOwner, id);
        vm.expectEmit(address(baseRegistrar));
        emit BaseRegistrar.NameRegistered(id, newOwner, duration + newBlockTimestamp);

        vm.warp(newBlockTimestamp);
        vm.prank(controller);
        uint256 expires = baseRegistrar.registerOnly(id, newOwner, duration);

        address ownerOfToken = baseRegistrar.ownerOf(id);
        assertTrue(ownerOfToken == newOwner);
        assertTrue(baseRegistrar.nameExpires(id) == expires);
    }

    function test_reverts_ifTheNameIsNotAvailable(address newOwner) public {
        vm.assume(newOwner != user);
        _registrationSetup();
        vm.warp(blockTimestamp);
        vm.prank(controller);
        baseRegistrar.registerOnly(id, user, duration);

        vm.expectRevert(abi.encodeWithSelector(BaseRegistrar.NotAvailable.selector, id));
        vm.prank(controller);
        baseRegistrar.registerOnly(id, newOwner, duration);
    }

    function test_reverts_ifTheNameIsNotAvailable_duringGracePeriod(address newOwner) public {
        vm.assume(newOwner != user);
        _registrationSetup();
        vm.warp(blockTimestamp);
        vm.prank(controller);
        baseRegistrar.registerOnly(id, user, duration);

        vm.expectRevert(abi.encodeWithSelector(BaseRegistrar.NotAvailable.selector, id));
        vm.warp(blockTimestamp + duration + GRACE_PERIOD - 1);
        vm.prank(controller);
        baseRegistrar.registerOnly(id, newOwner, duration);
    }
}
