//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test, console} from "forge-std/Test.sol";
import {StablePriceOracle} from "src/L2/StablePriceOracle.sol";

contract StablePriceFuzzTest is Test {
    StablePriceOracle stablePriceOracle;

    function setUp(uint256 fuzz) internal {
        uint256[] memory rentPrices = new uint256[](6);
        for (uint256 i = 0; i < 6; i++) {
            rentPrices[i] = uint256(keccak256(abi.encodePacked(fuzz, i))) % 1e14;
        }
        stablePriceOracle = new StablePriceOracle(rentPrices);
    }

    function test_price(string memory name, uint256 expires, uint256 duration, uint256 fuzz) public {
        setUp(fuzz);
        vm.assume(bytes(name).length > 0 && bytes(name).length <= 512);
        duration = duration % 1e18;
        stablePriceOracle.price(name, expires, duration);
    }
}
