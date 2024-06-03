//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {StablePriceOracle} from "src/L2/StablePriceOracle.sol";
import {StablePriceOracleBase} from "./ConstructorTest.t.sol";

contract Premium is StablePriceOracleBase {
    function test_AttoUSDToWei() public view {
        uint256 attoUSD = 3e13; // precise to ten decimal places
        uint256 expectedWei = 1e18;
        uint256 convertedWei = stablePriceOracle.attoUSDToWei(attoUSD);
        assertEq(convertedWei, expectedWei);
    }
}