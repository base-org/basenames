//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {AttestationValidatorBase} from "./AttestationValidatorBase.t.sol";
import {SybilResistanceVerifier} from "src/lib/SybilResistanceVerifier.sol";
import {Attestation} from "eas-contracts/IEAS.sol";
import "verifications/libraries/AttestationErrors.sol";

contract IsValidDiscountRegistration is AttestationValidatorBase {
    function test_reverts_whenTheAttestation_isExpired() public {
        Attestation memory att = _getDefaultAttestation();
        att.expirationTime = uint64(block.timestamp);
        _setAttestation(att);
        vm.expectRevert(abi.encodeWithSelector(AttestationExpired.selector, uid, block.timestamp));
        validator.isValidDiscountRegistration(user, _getDefaultValidationData());
    }

    function test_reverts_whenTheAttestation_hasBeenRevoked() public {
        Attestation memory att = _getDefaultAttestation();
        att.revocationTime = uint64(block.timestamp);
        _setAttestation(att);
        vm.expectRevert(abi.encodeWithSelector(AttestationRevoked.selector, uid, block.timestamp));
        validator.isValidDiscountRegistration(user, _getDefaultValidationData());
    }

    function test_reverts_whenTheAttestation_hasNoAttester() public {
        Attestation memory att = _getDefaultAttestation();
        att.attester = address(0);
        _setAttestation(att);
        vm.expectRevert(abi.encodeWithSelector(AttestationInvariantViolation.selector, "missing attester"));
        validator.isValidDiscountRegistration(user, _getDefaultValidationData());
    }

    function test_reverts_whenTheAttestation_hasNoSchema() public {
        Attestation memory att = _getDefaultAttestation();
        att.schema = bytes32(0);
        _setAttestation(att);
        vm.expectRevert(abi.encodeWithSelector(AttestationInvariantViolation.selector, "missing schema"));
        validator.isValidDiscountRegistration(user, _getDefaultValidationData());
    }

    function test_reverts_whenTheValidationData_claimerAddressMismatch() public {
        address notUser = makeAddr("anon");
        bytes memory validationData = _getDefaultValidationData();
        (, uint64 expires, bytes memory sig) = abi.decode(validationData, (address, uint64, bytes));
        bytes memory claimerMismatchValidationData = abi.encode(notUser, expires, sig);

        vm.expectRevert(abi.encodeWithSelector(SybilResistanceVerifier.ClaimerAddressMismatch.selector, notUser, user));
        validator.isValidDiscountRegistration(user, claimerMismatchValidationData);
    }

    function test_reverts_whenTheValidationData_signatureIsExpired() public {
        bytes memory validationData = _getDefaultValidationData();
        (address expectedClaimer,, bytes memory sig) = abi.decode(validationData, (address, uint64, bytes));
        bytes memory claimerMismatchValidationData = abi.encode(expectedClaimer, (block.timestamp - 1), sig);

        vm.expectRevert(abi.encodeWithSelector(SybilResistanceVerifier.SignatureExpired.selector));
        validator.isValidDiscountRegistration(user, claimerMismatchValidationData);
    }

    function test_returnsFalse_whenTheExpectedSignerMismatches(uint256 pk) public view {
        vm.assume(pk != signerPk && pk != 0 && pk < type(uint128).max);
        address badSigner = vm.addr(pk);
        bytes32 digest = SybilResistanceVerifier._makeSignatureHash(address(validator), badSigner, user, expires);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, digest);
        bytes memory sig = abi.encodePacked(r, s, v);
        bytes memory badSignerValidationData = abi.encode(user, expires, sig);

        assertFalse(validator.isValidDiscountRegistration(user, badSignerValidationData));
    }

    function test_returnsTrue_whenEverythingIsHappy() public {
        assertTrue(validator.isValidDiscountRegistration(user, _getDefaultValidationData()));
    }
}
