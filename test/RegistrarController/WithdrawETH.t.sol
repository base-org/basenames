// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {RegistrarControllerBase} from "./RegistrarControllerBase.t.sol";
import {RegistrarController} from "src/L2/RegistrarController.sol";
import {IPriceOracle} from "src/L2/interface/IPriceOracle.sol";

contract WithdrawETH is RegistrarControllerBase {
    function test_alwaysSendsTheBalanceToTheOwner(address caller) public {
        vm.deal(address(controller), 1 ether);
        assertEq(payments.balance, 0);
        vm.prank(caller);
        controller.withdrawETH();
        assertEq(payments.balance, 1 ether);
    }
}
