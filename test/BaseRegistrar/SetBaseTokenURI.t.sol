//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {BaseRegistrar} from "src/L2/BaseRegistrar.sol";
import {BaseRegistrarBase} from "./BaseRegistrarBase.t.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {LibString} from "solady/utils/LibString.sol";

contract SetBaseTokenURI is BaseRegistrarBase {
    using LibString for uint256;

    string public newBaseURI = "https://newurl.org/";

    function test_allowsTheOwnerToSetTheBaseURI() public {
        vm.prank(owner);
        baseRegistrar.setBaseTokenURI(newBaseURI);
        uint256 tokenID = 1;
        string memory returnedURI = baseRegistrar.tokenURI(1);
        string memory expectedURI = string.concat(newBaseURI, tokenID.toString());
        assertEq(keccak256(bytes(returnedURI)), keccak256(bytes(expectedURI)));
    }

    function test_reverts_whenCalledByNonOwner(address caller) public {
        vm.assume(caller != owner);
        vm.prank(caller);
        vm.expectRevert(Ownable.Unauthorized.selector);
        baseRegistrar.setBaseTokenURI(newBaseURI);
    }
}
