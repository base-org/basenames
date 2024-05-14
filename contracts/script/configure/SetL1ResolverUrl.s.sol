// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import "src/L1/L1Resolver.sol";

contract SetL1ResolverUrl is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address resolverAddress = 0x5F15c3B5949F5767F5Ca9013a8E4Ca4D97a053eD;
        vm.startBroadcast(deployerPrivateKey);

        string memory NEW_URL = "";

        L1Resolver resolver = L1Resolver(resolverAddress);
        resolver.setUrl(NEW_URL);

        vm.stopBroadcast();
    }
}
