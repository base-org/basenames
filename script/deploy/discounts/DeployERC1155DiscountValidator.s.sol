// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import {ERC1155DiscountValidator} from "src/L2/discounts/ERC1155DiscountValidator.sol";
import {MockERC1155} from "test/mocks/MockERC1155.sol";

contract DeployERC1155DiscountValidator is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddr = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        MockERC1155 token = new MockERC1155();
        token.mint(deployerAddr, 1, 1);
        console.log("Mock ERC1155 token address:");
        console.log(address(token));

        ERC1155DiscountValidator validator = new ERC1155DiscountValidator(address(token), 1);

        console.log("Discount Validator deployed to:");
        console.log(address(validator));

        vm.stopBroadcast();
    }
}
