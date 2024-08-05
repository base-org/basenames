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
        prices[0] = 316_808_781_402;
        prices[1] = 31_680_878_140;
        prices[2] = 3_168_087_814;
        prices[3] = 316_808_781;
        prices[4] = 31_680_878;
        prices[5] = 3_168_087; // 3,168,808.781402895 = 1e14 / (365.25 * 24 * 3600)
        uint256 premiumStart = 500 ether;
        uint256 totalDays = 28 days;

        StablePriceOracle oracle = new ExponentialPremiumPriceOracle(prices, premiumStart, totalDays);
        console.log("Price Oracle deployed to:");
        console.log(address(oracle));

        vm.stopBroadcast();
    }
}
