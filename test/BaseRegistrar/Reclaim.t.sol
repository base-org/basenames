//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {BaseRegistrar} from "src/L2/BaseRegistrar.sol";
import {BaseRegistrarBase} from "./BaseRegistrarBase.t.sol";
import {ERC721} from "lib/solady/src/tokens/ERC721.sol";
import {ENS} from "ens-contracts/registry/ENS.sol";
import {BASE_ETH_NODE, GRACE_PERIOD} from "src/util/Constants.sol";

contract Reclaim is BaseRegistrarBase {
    function test_reverts_whenNotLive() public {
        vm.prank(address(baseRegistrar));
        registry.setOwner(BASE_ETH_NODE, makeAddr("0xdead"));

        vm.expectRevert(BaseRegistrar.RegistrarNotLive.selector);

        baseRegistrar.reclaim(id, user);
    }

    function test_reverts_whenCalledByNonOwnerOrApprovedOperator(address caller) public {
        vm.assume(caller != address(0) && caller != user);
        _registrationSetup();
        _registerName(label, user, duration);

        vm.expectRevert(abi.encodeWithSelector(BaseRegistrar.NotApprovedOwner.selector, id, caller));

        vm.prank(caller);
        baseRegistrar.reclaim(id, caller);
    }

    function test_reverts_whenCalledAfterExpiry() public {
        _registrationSetup();
        uint256 expires = _registerName(label, user, duration);

        vm.expectRevert(abi.encodeWithSelector(BaseRegistrar.Expired.selector, id));

        vm.warp(expires + 1);
        vm.prank(user);
        baseRegistrar.reclaim(id, user);
    }

    function test_reclaimsOwnership_whenCalledByOwner_beforeExpiry() public {
        _registrationSetup();
        uint256 expires = _registerName(label, user, duration);

        vm.expectEmit();
        emit ENS.NewOwner(BASE_ETH_NODE, label, user);

        vm.warp(expires - 1);
        vm.prank(user);
        baseRegistrar.reclaim(id, user);
    }

    function test_reclaimsOwnership_whenCalledByOperator_beforeExpiry(address operator) public {
        vm.assume(operator != address(0) && operator != user);
        _registrationSetup();

        uint256 expires = _registerName(label, user, duration);
        vm.prank(user);
        baseRegistrar.approve(operator, id);

        vm.expectEmit();
        emit ENS.NewOwner(BASE_ETH_NODE, label, user);

        vm.warp(expires - 1);
        vm.prank(operator);
        baseRegistrar.reclaim(id, user);
    }

    function test_reclaimsOwnership_whenCalledByOperator_approvedForAll(address operator) public {
        vm.assume(operator != address(0) && operator != user);
        _registrationSetup();
        uint256 expires = _registerName(label, user, duration);

        vm.expectEmit();
        emit ERC721.ApprovalForAll(user, operator, true);
        vm.prank(user);
        baseRegistrar.setApprovalForAll(operator, true);

        vm.expectEmit();
        emit ENS.NewOwner(BASE_ETH_NODE, label, user);

        vm.warp(expires - 1);
        vm.prank(operator);
        baseRegistrar.reclaim(id, user);
    }
}
