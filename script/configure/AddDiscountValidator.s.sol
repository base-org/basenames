// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import {RegistrarController} from "src/L2/RegistrarController.sol";

contract AddDiscountValidator is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        ////////////////////////////////////////////////
        bytes32 key = keccak256("erc1155.discount.validator");
        RegistrarController.DiscountDetails memory details = RegistrarController.DiscountDetails({
            active: true,
            discountValidator: vm.envAddress("ERC1155_DISCOUNT_VALIDATOR"),
            key: key,
            discount: 0.001 ether
        });
        ////////////////////////////////////////////////

        address controllerAddr = vm.envAddress("REGISTRAR_CONTROLLER_ADDR");
        RegistrarController controller = RegistrarController(controllerAddr);

        controller.setDiscountDetails(details);

        vm.stopBroadcast();
    }
}
