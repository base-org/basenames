// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {RegistrarControllerBase} from "./RegistrarControllerBase.t.sol";
import {RegistrarController} from "src/L2/RegistrarController.sol";
import {console} from "forge-std/Test.sol";



contract RegisterRecords is RegistrarControllerBase {

    function _generateData(uint256 size) internal pure returns (bytes[] memory) {
        bytes[] memory data = new bytes[](size);
        string memory name = "name";
        for (uint256 i = 0; i < size; i++) {
            data[i] = bytes(name);
        }
        return data;
    }

    function test_registersSuccessfully_variableRecords(uint256 size) public {
        vm.assume(size < 20);
        vm.deal(user, 1 ether);
        RegistrarController.RegisterRequest memory request = _getDefaultRegisterRequest();
        request.data = _generateData(size);

        uint256 price = controller.registerPrice(request.name, request.duration);
        base.setAvailable(uint256(nameLabel), true);
        uint256 expires = block.timestamp + request.duration;
        base.setNameExpires(uint256(nameLabel), expires);

        vm.expectEmit(address(controller));
        emit RegistrarController.ETHPaymentProcessed(user, price);
        vm.expectEmit(address(controller));
        emit RegistrarController.NameRegistered(request.name, nameLabel, user, expires);

        vm.prank(user);
        controller.register{value: price}(request);
        assertTrue(reverse.hasClaimed(user));
    }
}