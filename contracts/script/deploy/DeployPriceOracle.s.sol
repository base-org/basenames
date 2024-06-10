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
        prices[0] = 1e19;
        prices[1] = 1e18;
        prices[2] = 1e17;
        prices[3] = 1e16;
        prices[4] = 1e15;
        prices[5] = 1e14;

        uint256 premiumStart = 500 ether;
        uint256 totalDays = 28 days;

        StablePriceOracle oracle = new ExponentialPremiumPriceOracle(prices, premiumStart, totalDays);
        console.log("Price Oracle deployed to:");
        console.log(address(oracle));

        vm.stopBroadcast();
    }
}
