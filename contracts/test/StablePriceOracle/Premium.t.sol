//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {StablePriceOracle} from "src/L2/StablePriceOracle.sol";
import {StablePriceOracleBase} from "./StablePriceOracleBase.t.sol";

contract Premium is StablePriceOracleBase {
    function test_premium() public view {
        uint256 premiumWei = stablePriceOracle.premium("abc", 0, 365 days);
        assertEq(premiumWei, 0);
    }
}
