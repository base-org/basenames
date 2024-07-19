//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {BaseRegistrarBase} from "./BaseRegistrarBase.t.sol";
import {BaseRegistrar} from "src/L2/BaseRegistrar.sol";
import {LibString} from "solady/utils/LibString.sol";

contract TokenURI is BaseRegistrarBase {
    using LibString for uint256;

    function test_tokenURIIsSetAsExpected() public {
        _registrationSetup();
        vm.warp(blockTimestamp);
        vm.prank(controller);
        baseRegistrar.register(id, user, duration);

        string memory expectedURI = string.concat(baseURI, id.toString());
        assertEq(keccak256(bytes(baseRegistrar.tokenURI(id))), keccak256(bytes(expectedURI)));
    }

    function test_reverts_ifTheTokenIsExpired() public {
        _registrationSetup();
        vm.warp(blockTimestamp);
        vm.prank(controller);
        uint256 expires = baseRegistrar.register(id, user, duration);
        vm.warp(expires + 1);

        vm.expectRevert(abi.encodeWithSelector(BaseRegistrar.Expired.selector, id));
        baseRegistrar.tokenURI(id);
    }

    function test_reverts_ifTheTokenIsNotOwned() public {
        vm.expectRevert(abi.encodeWithSelector(BaseRegistrar.Expired.selector, id));
        baseRegistrar.tokenURI(id);
    }
}
