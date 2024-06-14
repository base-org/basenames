//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {BaseRegistrarBase} from "./BaseRegistrarBase.t.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {IERC165} from "openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";

interface Reclaim {
    function reclaim(uint256, address) external;
}

contract SupportsInterface is BaseRegistrarBase {
    function test_supportsMetaInterfaceId() public view {
        assertTrue(baseRegistrar.supportsInterface(type(IERC165).interfaceId));
    }

    function test_supportsIERC721InterfaceId() public view {
        assertTrue(baseRegistrar.supportsInterface(type(IERC721).interfaceId));
    }

    function test_supportsReclaimInterfaceId() public view {
        assertTrue(baseRegistrar.supportsInterface(type(Reclaim).interfaceId));
    }

    function test_doesNotSupportArbitraryInterfaceIds(bytes4 ifaceId) public view {
        vm.assume(
            ifaceId != type(IERC165).interfaceId && ifaceId != type(IERC721).interfaceId
                && ifaceId != type(Reclaim).interfaceId
        );
        assertFalse(baseRegistrar.supportsInterface(ifaceId));
    }
}
