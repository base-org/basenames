//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {BaseRegistrar} from "src/L2/BaseRegistrar.sol";
import {BaseRegistrarBase} from "./BaseRegistrarBase.t.sol";
import {ERC721} from "lib/solady/src/tokens/ERC721.sol";
import {ENS} from "ens-contracts/registry/ENS.sol";
import {BASE_ETH_NODE, GRACE_PERIOD} from "src/util/Constants.sol";
import {NameEncoder} from "ens-contracts/utils/NameEncoder.sol";
import "forge-std/console.sol";

contract Register is BaseRegistrarBase {
    uint256 id = uint256(keccak256("test")); // token id for test.base.eth
    uint256 duration = 30 days;
    uint256 blockTimestamp = 1716496498;     // May 23, 2024

    function test_reverts_whenTheRegistrarIsNotLive() public {
        vm.prank(address(baseRegistrar));
        registry.setOwner(BASE_ETH_NODE, owner);
        vm.expectRevert(BaseRegistrar.RegistrarNotLive.selector);
        baseRegistrar.register(id, user, duration);
    }

    function test_reverts_whenCalledByNonController(address caller) public {
        vm.prank(caller);
        vm.expectRevert(BaseRegistrar.OnlyController.selector);
        baseRegistrar.register(id, user, duration);
    }

    function test_successfullyRegisters() public {
        _registrationSetup();

        vm.expectEmit(address(baseRegistrar));
        emit ERC721.Transfer(address(0), user, id);
        vm.expectEmit(address(registry));
        emit ENS.NewOwner(BASE_ETH_NODE, bytes32(id), user);
        vm.expectEmit(address(baseRegistrar));
        emit BaseRegistrar.NameRegistered(id, user, duration + blockTimestamp);

        vm.warp(blockTimestamp); 
        vm.prank(owner);
        uint256 expires = baseRegistrar.register(id, user, duration);

        address ownerOfToken = baseRegistrar.ownerOf(id);
        assertTrue(ownerOfToken == user);
        assertTrue(baseRegistrar.nameExpires(id) == expires);
    }

    function test_successfullyRegisters_afterExpiry(address newOwner) public {
        vm.assume(newOwner != user);
        _registrationSetup();

        vm.warp(blockTimestamp); 
        vm.prank(owner);
        baseRegistrar.register(id, user, duration);

        uint256 newBlockTimestamp = blockTimestamp + duration + GRACE_PERIOD + 1;
        vm.expectEmit(address(baseRegistrar));
        emit ERC721.Transfer(address(0), newOwner, id);
        vm.expectEmit(address(registry));
        emit ENS.NewOwner(BASE_ETH_NODE, bytes32(id), newOwner);
        vm.expectEmit(address(baseRegistrar));
        emit BaseRegistrar.NameRegistered(id, newOwner, duration + newBlockTimestamp);

        vm.warp(newBlockTimestamp); 
        vm.prank(owner);
        uint256 expires = baseRegistrar.register(id, newOwner, duration);

        address ownerOfToken = baseRegistrar.ownerOf(id);
        assertTrue(ownerOfToken == newOwner);
        assertTrue(baseRegistrar.nameExpires(id) == expires);
    }

    function test_reverts_ifTheNameIsNotAvailable(address newOwner) public {
        vm.assume(newOwner != user);
        _registrationSetup();
        vm.warp(blockTimestamp); 
        vm.prank(owner);
        baseRegistrar.register(id, user, duration);

        vm.expectRevert(abi.encodeWithSelector(BaseRegistrar.NotAvailable.selector, id));
        vm.prank(owner);
        baseRegistrar.register(id, newOwner, duration);
    }
    
    function test_reverts_ifTheNameIsNotAvailable_duringGracePeriod(address newOwner) public {
        vm.assume(newOwner != user);
        _registrationSetup();
        vm.warp(blockTimestamp); 
        vm.prank(owner);
        baseRegistrar.register(id, user, duration);

        vm.expectRevert(abi.encodeWithSelector(BaseRegistrar.NotAvailable.selector, id));
        vm.warp(blockTimestamp + duration + GRACE_PERIOD - 1);
        vm.prank(owner);
        baseRegistrar.register(id, newOwner, duration);
    }
    
    function _registrationSetup() internal {
        vm.prank(owner);
        baseRegistrar.addController(owner);
    }

    function _testNode() internal pure returns (bytes32) {
        (, bytes32 testNode) = NameEncoder.dnsEncodeName("test.base.eth");
        return testNode;
    }
}