//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {BaseRegistrarBase} from "./BaseRegistrarBase.t.sol";
import {BaseRegistrar} from "src/L2/BaseRegistrar.sol";
import {Ownable} from "solady/auth/Ownable.sol";

contract SetContractURI is BaseRegistrarBase {
    string newContractURI = "NewURI";

    function test_allowsTheOwnerToSetTheContractURI() public {
        vm.expectEmit(address(baseRegistrar));
        emit BaseRegistrar.ContractURIUpdated();

        vm.prank(owner);
        baseRegistrar.setContractURI(newContractURI);
        assertEq(keccak256(bytes(baseRegistrar.contractURI())), keccak256(bytes(newContractURI)));
    }

    function test_reverts_whenCalledByNonOwner(address caller) public {
        vm.assume(caller != owner);
        vm.prank(caller);
        vm.expectRevert(Ownable.Unauthorized.selector);
        baseRegistrar.setBaseTokenURI(newContractURI);
    }
}
