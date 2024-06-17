// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import {RegistrarController} from "src/L2/RegistrarController.sol";
import {L2Resolver} from "src/L2/L2Resolver.sol";
import {TextResolver} from "src/L2/L2Resolver.sol";
import "src/util/Constants.sol";
import "ens-contracts/utils/NameEncoder.sol";
import "solady/utils/LibString.sol";

interface AddrResolver {
    function setAddr(bytes32 node, address addr) external;
}

contract RegisterNewName is Script {
    // NAME AND RECORD DEFS /////////////////////////////
    string NAME = "steve";
    uint256 duration = 365 days;
    address RESOLVED_ADDR = 0xB18e4C959bccc8EF86D78DC297fb5efA99550d85;
    bytes32 discountKey = keccak256("testnet.discount.validator");
    string textKey = "amicool";
    string textValue = "yes";
    /////////////////////////////////////////////////////

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address controllerAddr = vm.envAddress("REGISTRAR_CONTROLLER_ADDR");
        RegistrarController controller = RegistrarController(controllerAddr);
        address resolverAddr = vm.envAddress("L2_RESOLVER_ADDR"); // l2 resolver

        RegistrarController.RegisterRequest memory request = RegistrarController.RegisterRequest({
            name: NAME,
            owner: RESOLVED_ADDR,
            duration: duration,
            resolver: resolverAddr,
            data: _packResolverData(),
            reverseRecord: false
        });

        controller.discountedRegister(request, discountKey, "");

        vm.stopBroadcast();
    }

    function _packResolverData() internal view returns (bytes[] memory) {
        (, bytes32 rootNode) = NameEncoder.dnsEncodeName("basetest.eth");
        bytes32 label = keccak256(bytes(NAME));
        bytes32 nodehash = keccak256(abi.encodePacked(rootNode, label));

        bytes memory addrData = abi.encodeWithSelector(AddrResolver.setAddr.selector, nodehash, RESOLVED_ADDR);
        bytes memory textData = abi.encodeWithSelector(TextResolver.setText.selector, nodehash, textKey, textValue);
        bytes[] memory data = new bytes[](2);
        data[0] = addrData;
        data[1] = textData;
        return data;
    }
}
