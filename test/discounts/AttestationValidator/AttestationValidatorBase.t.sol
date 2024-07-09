//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {AttestationValidator} from "src/L2/discounts/AttestationValidator.sol";
import {MockAttestationIndexer} from "test/mocks/MockAttestationIndexer.sol";
import {MockEAS} from "test/mocks/MockEAS.sol";
import {IEAS} from "eas-contracts/IEAS.sol";
import {Predeploys} from "verifications/libraries/Predeploys.sol";
import {Attestation} from "eas-contracts/IEAS.sol";
import {SybilResistanceVerifier} from "src/lib/SybilResistanceVerifier.sol";

contract AttestationValidatorBase is Test {
    AttestationValidator public validator;

    address public owner = makeAddr("owner");
    address public signer;
    uint256 public signerPk;
    address public user = makeAddr("user");
    address public attester = makeAddr("attester");
    bytes32 schema;
    bytes32 uid;
    uint64 time = 1717200000;
    uint64 expires = 1893456000;

    function setUp() public {
        vm.warp(time);
        (signer, signerPk) = makeAddrAndKey("signer");
        schema = keccak256("schema");
        uid = keccak256("uid");
        MockAttestationIndexer indexer = new MockAttestationIndexer(uid);
        _setupMockEAS();
        validator = new AttestationValidator(owner, signer, schema, address(indexer));
    }

    function _setupMockEAS() internal {
        MockEAS eas = new MockEAS();
        vm.etch(Predeploys.EAS, address(eas).code);
        MockEAS(Predeploys.EAS).setAttestattion(_getDefaultAttestation());
    }

    function _setAttestation(Attestation memory att) internal {
        MockEAS(Predeploys.EAS).setAttestattion(att);
    }

    function _getDefaultAttestation() internal virtual returns (Attestation memory) {
        return Attestation({
            uid: uid,
            schema: schema,
            time: time,
            expirationTime: expires,
            revocationTime: 0,
            refUID: bytes32(0),
            recipient: user,
            attester: attester,
            revocable: true,
            data: bytes("")
        });
    }

    function _getDefaultValidationData() internal virtual returns (bytes memory) {
        bytes32 digest = SybilResistanceVerifier._makeSignatureHash(address(validator), signer, user, expires);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPk, digest);
        bytes memory sig = abi.encodePacked(r, s, v);
        return abi.encode(user, expires, sig);
    }
}
