//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {IntegrationTestBase} from "./IntegrationTestBase.t.sol";
import {RegistrarController} from "src/L2/RegistrarController.sol";

contract LaunchAuctionRegistrations is IntegrationTestBase {
    string name = "alice";
    uint256 duration = 365.25 days;
    uint256 id = uint256(keccak256(bytes(name)));

    function test_register_at_LaunchTime() public {
        vm.warp(LAUNCH_TIME);
        _register("launch time");
    }

    function test_register_oneHourAfter_LaunchTime() public {
        vm.warp(LAUNCH_TIME + 1 hours);
        _register("launch + 1 hour");
    }

    function test_register_threeHoursAfter_LaunchTime() public {
        vm.warp(LAUNCH_TIME + 3 hours);
        _register("launch + 3 hours");
    }

    function test_register_oneDayAfter_LaunchTime() public {
        vm.warp(LAUNCH_TIME + 1 days);
        _register("launch + 1 day");
    }

    function test_register_justBefore_launchAuctionEnds() public {
        vm.warp(LAUNCH_TIME + (LAUNCH_AUCTION_DURATION_HOURS * 1 hours) - 1);
        _register("1 second before auction ends");
    }

    function test_register_justAfter_launchAuctionEnds() public {
        vm.warp(LAUNCH_TIME + (LAUNCH_AUCTION_DURATION_HOURS * 1 hours));
        _register("auction end time");
    }

    function test_register_oneDayAfter_launchAuctionEnds() public {
        vm.warp(LAUNCH_TIME + (LAUNCH_AUCTION_DURATION_HOURS * 1 hours) + 1 days);
        _register("1 day after auction ends");
    }

    function _register(string memory logCase) internal {
        uint256 price = registrarController.registerPrice(name, duration);
        vm.deal(alice, price);

        RegistrarController.RegisterRequest memory request = RegistrarController.RegisterRequest({
            name: name,
            owner: alice,
            duration: duration,
            resolver: address(defaultL2Resolver),
            data: new bytes[](0),
            reverseRecord: true
        });

        vm.expectEmit(address(registrarController));
        emit RegistrarController.ETHPaymentProcessed(alice, price);

        vm.prank(alice);
        registrarController.register{value: price}(request);
        assertEq(baseRegistrar.ownerOf(id), alice);

        console.log("______________________________");
        console.log("Registering at", logCase);
        console.log("Timestamp: ", block.timestamp);
        console.log("Price (WEI): ", price);
        console.log("______________________________");
    }
}
