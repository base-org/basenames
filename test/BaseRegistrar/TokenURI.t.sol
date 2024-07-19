//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {BaseRegistrarBase} from "./BaseRegistrarBase.t.sol";
import {LibString} from "solady/utils/LibString.sol";

contract TokenURI is BaseRegistrarBase {
    using LibString for uint256;

    function test_tokenURIIsSetAsExpected() public view {
        uint256 tokenID = 1;
        string memory expectedURI = string.concat(baseURI, tokenID.toString());
        assertEq(keccak256(bytes(baseRegistrar.tokenURI(1))), keccak256(bytes(expectedURI)));
    }
}
