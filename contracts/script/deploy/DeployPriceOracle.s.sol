// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";

import {StablePriceOracle} from "src/L2/StablePriceOracle.sol";
import {ExponentialPremiumPriceOracle} from "src/L2/ExponentialPremiumPriceOracle.sol";

contract DeployPriceOracle is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        uint256[] memory prices = new uint256[](6);
        prices[0] = 317_097_919_837;
        prices[1] = 31_709_791_983;
        prices[2] = 3_170_979_198;
        prices[3] = 317_097_919;
        prices[4] = 31_709_791;
        prices[5] = 3_170_979; //3,170,979.1983764587 = 1e14 / (365 * 24 * 3600) 
        uint256 premiumStart = 500 ether;
        uint256 totalDays = 28 days;

        StablePriceOracle oracle = new ExponentialPremiumPriceOracle(prices, premiumStart, totalDays);
        console.log("Price Oracle deployed to:");
        console.log(address(oracle));

        vm.stopBroadcast();
    }
}
