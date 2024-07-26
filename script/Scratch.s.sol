// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import {Registry} from "src/L2/Registry.sol";
import {EARegistrarController} from "src/L2/EARegistrarController.sol";
import "src/util/Constants.sol";

contract Scratch is Script {
    function run() external view {
        uint256 pkey = vm.envUint("PREMINT_PRIVATE_KEY");
        address a = vm.addr(pkey);
        console.log(a);
    }

    function encodeProof(bytes32[] memory proof) external {
        bytes memory data = abi.encode(proof);
        bytes[] memory empty = new bytes[](0);
        bytes32 key = 0xf5f55dcafd77c74cf5ff621cd6531daacd008302c7462bf9e7cda1cf2df6ed42;
        EARegistrarController.RegisterRequest memory request = EARegistrarController.RegisterRequest({
            name: "brian",
            owner: 0x5b76f5B8fc9D700624F78208132f91AD4e61a1f0,
            duration: 365 days, 
            resolver: 0xC6d566A56A1aFf6508b41f6c90ff131615583BCD,
            data: empty,
            reverseRecord: true
        });
        console.logBytes(abi.encodeWithSelector(EARegistrarController.discountedRegister.selector, request, key, data));
    }
}