//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Attestation} from "eas-contracts/EAS.sol";

contract MockEAS {
    bytes32 schema;
    Attestation att;

    function setAttestattion(Attestation memory att_) public {
        att = att_;
    }

    function getAttestation(bytes32) external view returns (Attestation memory) {
        return att;
    }
}
