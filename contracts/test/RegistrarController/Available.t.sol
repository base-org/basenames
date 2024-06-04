// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {RegistrarControllerBase} from "./RegistrarControllerBase.t.sol";
import {BASE_ETH_NODE, ETH_NODE} from "src/util/Constants.sol";

contract Available is RegistrarControllerBase {

    function test_returnsFalse_whenNotAvailableOnBase() public {
        base.setAvailable(uint256(nameLabel), false);
        assertFalse(controller.available(name));
    }

    function test_returnsFalse_whenInvalidLength() public {
        base.setAvailable(uint256(shortNameLabel), true);
        assertFalse(controller.available(shortName));
    }

    function test_returnsTrue_whenValidAndAvailable() public {
        base.setAvailable(uint256(nameLabel), true);
        assertTrue(controller.available(name));
    }
}
