// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import "src/L1/L1Resolver.sol";

contract SetL1ResolverUrl is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address resolverAddress = vm.envAddress("L1_RESOLVER_ADDR");
        vm.startBroadcast(deployerPrivateKey);

        string memory NEW_URL =
            "https://api-entry-gateway-development.cbhq.net/api/v1/domain/resolver/resolveDomain/{sender}/{data}";

        L1Resolver resolver = L1Resolver(resolverAddress);
        resolver.setUrl(NEW_URL);

        vm.stopBroadcast();
    }
}
