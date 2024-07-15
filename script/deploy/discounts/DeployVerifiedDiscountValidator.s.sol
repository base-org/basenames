// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import {AttestationValidator} from "src/L2/discounts/AttestationValidator.sol";

contract DeployVerifiedDiscountValidator is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddr = vm.addr(deployerPrivateKey);
        address TRUSTED_SIGNER_ADDRESS = 0xB6944B3074F40959E1166fe010a3F86B02cF2b7c;
        bytes32 VERIFIED_ACCOUNT_SCHEMA = 0x2f34a2ffe5f87b2f45fbc7c784896b768d77261e2f24f77341ae43751c765a69;
        address INDEXER = 0xd147a19c3B085Fb9B0c15D2EAAFC6CB086ea849B;
        vm.startBroadcast(deployerPrivateKey);

        AttestationValidator validator =
            new AttestationValidator(deployerAddr, TRUSTED_SIGNER_ADDRESS, VERIFIED_ACCOUNT_SCHEMA, INDEXER);
        console.log("Discount Validator deployed to:");
        console.log(address(validator));

        vm.stopBroadcast();
    }
}
