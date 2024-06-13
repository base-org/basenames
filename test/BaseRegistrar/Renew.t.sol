//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {BaseRegistrar} from "src/L2/BaseRegistrar.sol";
import {BaseRegistrarBase} from "./BaseRegistrarBase.t.sol";
import {ERC721} from "lib/solady/src/tokens/ERC721.sol";
import {ENS} from "ens-contracts/registry/ENS.sol";
import {BASE_ETH_NODE, GRACE_PERIOD} from "src/util/Constants.sol";

contract Renew is BaseRegistrarBase {
    function test_reverts_whenCalledByNonController(address caller) public {
        vm.assume(caller != controller);
        vm.prank(caller);

        vm.expectRevert(BaseRegistrar.OnlyController.selector);

        baseRegistrar.renew(id, duration);
    }

    function test_reverts_whenNotLive() public {
        vm.prank(address(baseRegistrar));
        registry.setOwner(BASE_ETH_NODE, makeAddr("0xdead"));

        vm.expectRevert(BaseRegistrar.RegistrarNotLive.selector);

        baseRegistrar.renew(id, duration);
    }

    function test_reverts_whenNotRegistered() public {
        _registrationSetup();

        vm.expectRevert(abi.encodeWithSelector(BaseRegistrar.NotRegisteredOrInGrace.selector, id));

        vm.prank(controller);
        vm.warp(blockTimestamp);
        baseRegistrar.renew(id, duration);
    }

    function test_reverts_whenNotInGracePeriod() public {
        _registrationSetup();
        uint256 expires = _registerName(label, user, duration);

        vm.expectRevert(abi.encodeWithSelector(BaseRegistrar.NotRegisteredOrInGrace.selector, id));

        vm.warp(expires + GRACE_PERIOD + 1);
        vm.prank(controller);
        baseRegistrar.renew(id, duration);
    }

    function test_renewsOwnershipSuccessfully_whenNotExpired() public {
        _registrationSetup();
        uint256 expires = _registerName(label, user, duration);

        vm.expectEmit();
        emit BaseRegistrar.NameRenewed(id, expires + duration);

        vm.warp(expires - 1);
        vm.prank(controller);
        uint256 renwedExpiry = baseRegistrar.renew(id, duration);
        assertTrue(renwedExpiry == expires + duration);
        assertTrue(baseRegistrar.ownerOf(id) == user);
    }

    function test_renewsOwnershipSuccessfully_whenInGracePeriod() public {
        _registrationSetup();
        uint256 expires = _registerName(label, user, duration);

        vm.expectEmit();
        emit BaseRegistrar.NameRenewed(id, expires + duration);

        vm.warp(expires + GRACE_PERIOD - 1);
        vm.prank(controller);
        uint256 renwedExpiry = baseRegistrar.renew(id, duration);
        assertTrue(renwedExpiry == expires + duration);
        assertTrue(baseRegistrar.ownerOf(id) == user);
    }
}
