//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test, console} from "forge-std/Test.sol";
import {StablePriceOracle} from "src/L2/StablePriceOracle.sol";

// contract StablePriceFuzzTest is Test {
//     StablePriceOracle stablePriceOracle;

//     function setUp(uint256 fuzzedBlockTimestamp, uint256 fuzzedGasLeft) internal {
        
//         uint256 fuzzedPrice = uint256(keccak256(abi.encodePacked(fuzzedBlockTimestamp, fuzzedGasLeft))) % 1e18;

//         mockOracle = new MockOracle(int256(fuzzedPrice));

//         uint256[] memory rentPrices = new uint256[](5);
//         for (uint256 i = 0; i < 5; i++) {
//             rentPrices[i] = uint256(keccak256(abi.encodePacked(fuzzedBlockTimestamp, fuzzedGasLeft, i))) % 1e6;
//         }
//         stablePriceOracle = new StablePriceOracle(mockOracle, rentPrices);
//     }

//     function test_price(string memory name, uint256 expires, uint256 duration) public {
//         uint256 fuzzedBlockTimestamp = uint256(keccak256(abi.encodePacked(expires, duration)));
//         uint256 fuzzedGasLeft = uint256(keccak256(abi.encodePacked(duration, expires)));
//         setUp(fuzzedBlockTimestamp, fuzzedGasLeft);

//         vm.assume(bytes(name).length > 0 && bytes(name).length <= 512);
//         stablePriceOracle.price(name, expires, duration);
//     }

//     function test_AttoUSDToWei(uint256 attoUSD) public {
//         uint256 fuzzedBlockTimestamp = uint256(keccak256(abi.encodePacked(attoUSD)));
//         uint256 fuzzedGasLeft = uint256(keccak256(abi.encodePacked(attoUSD)));
//         setUp(fuzzedBlockTimestamp, fuzzedGasLeft);

//         uint256 scaledAttoUSD = attoUSD / 1e10;
//         stablePriceOracle.attoUSDToWei(scaledAttoUSD);
//     }

//     // function isValidUnicodeString(string memory str) internal pure returns (bool) {
//     // bytes memory b = bytes(str);
//     // for (uint i = 0; i < b.length; i++) {
//     //     bytes1 char = b[i];
//     //     if (char >= 0x80) {
//     //         if (char < 0xC2 || char > 0xF4) {
//     //             return false;
//     //         }
//     //         i++;
//     //         if (i >= b.length || b[i] < 0x80 || b[i] > 0xBF) {
//     //             return false;
//     //         }
//     //     }
//     // }
//     // return true;
//     // }
// }