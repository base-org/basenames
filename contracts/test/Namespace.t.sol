//SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {NameEncoder} from "ens-contracts/utils/NameEncoder.sol";

contract Namespace is Test {

    function test_encodeName() public pure {
        (bytes memory dnsName, bytes32 node) = NameEncoder.dnsEncodeName("base.eth");
        console2.logBytes(dnsName);
        console2.logBytes32(node);
    }
}