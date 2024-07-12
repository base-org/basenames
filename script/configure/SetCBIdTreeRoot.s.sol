// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import "src/L2/discounts/CBIdDiscountValidator.sol";

contract SetCBIdTreeRoot is Script {
    bytes32 root = 0x8cbc28e840d1cd2accddec6592a4bffce2ca38c6c559c252504f342dd46acbb6;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address cbid = vm.envAddress("CBID_DISCOUNT_VALIDATOR");

        CBIdDiscountValidator(cbid).setRoot(root);

        vm.stopBroadcast();
    }
}
