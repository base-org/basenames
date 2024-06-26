// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import {CBIdDiscountValidator} from "src/L2/discounts/CBIdDiscountValidator.sol";

contract DeployCBIDDiscountValidator is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddr = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        bytes32 ROOT = 0x06d3fa5259a86780f0f1d68a471fd5661caf196d5970ac4eda6abf068ba5659f;

        CBIdDiscountValidator validator = new CBIdDiscountValidator(deployerAddr, ROOT);
        console.log("Discount Validator deployed to:");
        console.log(address(validator));

        vm.stopBroadcast();
    }
}

/*
Merkle root: 06d3fa5259a86780f0f1d68a471fd5661caf196d5970ac4eda6abf068ba5659f
_____________
Merkle proof for 0x4e37E29A4191Ea43A68eab2E5c5bE79e04636987
[
  '0x56fff5b37fd2238fb735764c1153a535c99d96f11ddb565cb96f11b9636c0211',
  '0xc66ad35282363b4c2fe5fab622b6f89cc21ab46e867c7c5186cdb4c1c0478e9a',
  '0x2fc5e169494983556a0af149a0588c6298294f0435460d69bea92887c9768a16'
]
Merkle proof for 0xcC864c0C7402320c84b5512629A41bD103553c77
[
  '0xfcc16bd5d895e0b3a190be64a43a82cad3a70015bcf76059c8db5709a9eebd9b',
  '0xc66ad35282363b4c2fe5fab622b6f89cc21ab46e867c7c5186cdb4c1c0478e9a',
  '0x2fc5e169494983556a0af149a0588c6298294f0435460d69bea92887c9768a16'
]
Merkle proof for 0x83a2A996eb98F2ec1BF8cAb9c2F617B0E3D79EC0
[
  '0x9455a8f7a8d425581528c298acbf75b06c9dace593ad78b2d9e10796dea5419a',
  '0xee76f3a1514e744fa7c421f7f27408228737ce67096a9fc5350aa8e21e30763c',
  '0x2fc5e169494983556a0af149a0588c6298294f0435460d69bea92887c9768a16'
]
Merkle proof for 0x411669670D0C7242E0B97477bcb335B0Ca66F730
[
  '0x9a00481a1b3f96ce3a2a0737513e9d51026f2eaa62d770211b5920eb16bcfeb1',
  '0xee76f3a1514e744fa7c421f7f27408228737ce67096a9fc5350aa8e21e30763c',
  '0x2fc5e169494983556a0af149a0588c6298294f0435460d69bea92887c9768a16'
]
Merkle proof for 0xe5546B2Bd78408DB7908F86251e7f694CF6397b9
[
  '0x768c6c63bfc042f4c91142faeafd0f6f0fa11403d1a97e8d2c97f0ee463cf677',
  '0x56ce3bbc909b90035ae373d32c56a9d81d26bb505dd935cdee6afc384bcaed8d',
  '0x17fb7c844842cc7127aeb7433bc69823fdee454380536c132f6077108ec45a03'
]
Merkle proof for 0xC8e360E2C3614bBfc3A6D72311A4C276cd5F652d
[
  '0xbb6eeb2728470dd6b47c5e4bcf5ee7156dd31cfdc580e26c5abeab3b21add81e',
  '0x56ce3bbc909b90035ae373d32c56a9d81d26bb505dd935cdee6afc384bcaed8d',
  '0x17fb7c844842cc7127aeb7433bc69823fdee454380536c132f6077108ec45a03'
]
Merkle proof for 0xF42d60143b371950be691462c06389a08C0e09Ef
[
  '0x26a70733a6a2e9ae08eeaa3c82951eb292f6f75ca398fa62a28c81e9aa31ab72',
  '0x17fb7c844842cc7127aeb7433bc69823fdee454380536c132f6077108ec45a03'
]
*/
