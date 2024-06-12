//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {BaseRegistrar} from "src/L2/BaseRegistrar.sol";
import {BaseRegistrarBase} from "./BaseRegistrarBase.t.sol";
import {GRACE_PERIOD} from "src/util/Constants.sol";

contract IsAvailable is BaseRegistrarBase {
    function test_returnsAvailabilityAsExpected() public {
        _registrationSetup();
        uint256 expires = _registerName(label, user, duration);
        assertFalse(baseRegistrar.isAvailable(id));

        vm.warp(expires + GRACE_PERIOD - 1); // in grace period
        assertFalse(baseRegistrar.isAvailable(id));

        vm.warp(expires + GRACE_PERIOD + 1); // past grace period
        assertTrue(baseRegistrar.isAvailable(id));
    }
}
