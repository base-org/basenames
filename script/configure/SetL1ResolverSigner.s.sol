// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import "src/L1/L1Resolver.sol";

contract SetL1ResolverSigner is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address resolverAddress = vm.envAddress("L1_RESOLVER_ADDR");
        vm.startBroadcast(deployerPrivateKey);

        address NEW_SIGNER = 0x0ae910AFA602F5460c4A6eDEc98A4F429901fAE2;
        address[] memory signers = new address[](1);
        signers[0] = NEW_SIGNER;

        L1Resolver resolver = L1Resolver(resolverAddress);
        console.log("connected to L1 resolver");
        resolver.addSigners(signers);

        vm.stopBroadcast();
    }
}
