// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {BaseRegistrar} from "./BaseRegistrar.sol";
import {StringUtils} from "ens-contracts/ethregistrar/StringUtils.sol";
import {Resolver} from "ens-contracts/resolvers/Resolver.sol";
import {ENS} from "ens-contracts/registry/ENS.sol";
import {ReverseRegistrar} from "ens-contracts/reverseRegistrar/ReverseRegistrar.sol";
import {ReverseClaimer} from "ens-contracts/reverseRegistrar/ReverseClaimer.sol";

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {IERC165} from "lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import {Address} from "lib/openzeppelin-contracts/contracts/utils/Address.sol";
import {INameWrapper} from "ens-contracts/wrapper/INameWrapper.sol";
import {ERC20Recoverable} from "ens-contracts/utils/ERC20Recoverable.sol";

import "lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";

error NameNotAvailable(string name);
error DurationTooShort(uint256 duration);
error ResolverRequiredWhenDataSupplied();
error InsufficientValue();
error Unauthorised(bytes32 node);

/**
 * @dev A registrar controller for registering and renewing names at fixed cost.
 */
contract Registrar is
    Ownable,
    IERC165,
    ERC20Recoverable,
    ReverseClaimer,
    AccessControl,
    EIP712
{
    using StringUtils for *;
    using Address for address;

    uint256 public constant MIN_REGISTRATION_DURATION = 28 days;
    bytes32 private constant ETH_NODE =
        0x7e7650bbd57a49caffbb4c83ce43045d2653261b7953b80d47500d9eb37b6134;
    uint64 private constant MAX_EXPIRY = type(uint64).max;
    BaseRegistrarImplementation immutable base;
    ReverseRegistrar public immutable reverseRegistrar;
    INameWrapper public immutable nameWrapper;

    mapping(bytes32 => uint256) public commitments;

    bytes32 public constant REGISTER_ROLE = keccak256("REGISTER_ROLE");
    bytes32 public constant RENEW_ROLE = keccak256("RENEW_ROLE");
    string private constant SIGNING_DOMAIN = "BaseNameService";
    string private constant SIGNATURE_VERSION = "1";

    event NameRegistered(
        string name,
        bytes32 indexed label,
        address indexed owner,
        uint256 baseCost,
        uint256 premium,
        uint256 expires
    );
    event NameRenewed(
        string name,
        bytes32 indexed label,
        uint256 cost,
        uint256 expires
    );

    constructor(
        BaseRegistrarImplementation _base,
        ReverseRegistrar _reverseRegistrar,
        INameWrapper _nameWrapper,
        ENS _ens
    )
        ReverseClaimer(_ens, msg.sender)
        EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION)
    {
        base = _base;
        reverseRegistrar = _reverseRegistrar;
        nameWrapper = _nameWrapper;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(REGISTER_ROLE, msg.sender);
        _grantRole(RENEW_ROLE, msg.sender);
    }

    struct RegisterRequest {
        string name;
        address owner;
        uint256 duration;
        uint256 validUntil;
        address resolver;
        bool reverseRecord;
        uint16 ownerControlledFuses;
        uint256 price;
        bytes signature;
    }

    struct RenewRequest {
        string name;
        uint256 duration;
        uint256 validUntil;
        uint256 price;
        bytes signature;
    }

    function valid(string memory name) public pure returns (bool) {
        return name.strlen() >= 3;
    }

    function available(string memory name) public view returns (bool) {
        bytes32 label = keccak256(bytes(name));
        return valid(name) && base.available(uint256(label));
    }

    function registerWithSignature(
        RegisterRequest calldata request,
        bytes[] calldata data
    ) public payable {
        address signer = _verifyRegisterRequest(request);

        require(
            hasRole(REGISTER_ROLE, signer),
            "Signature invalid or unauthorized"
        );

        require(request.validUntil > block.timestamp, "Request expired");

        if (msg.value < request.price) {
            revert InsufficientValue();
        }

        _checkNameAndDuration(request.name, request.duration);

        uint256 expires = nameWrapper.registerAndWrapETH2LD(
            request.name,
            request.owner,
            request.duration,
            request.resolver,
            request.ownerControlledFuses
        );

        if (data.length > 0) {
            _setRecords(request.resolver, keccak256(bytes(request.name)), data);
        }

        if (request.reverseRecord) {
            _setReverseRecord(request.name, request.resolver, msg.sender);
        }

        emit NameRegistered(
            request.name,
            keccak256(bytes(request.name)),
            request.owner,
            request.price,
            request.price,
            expires
        );
    }

    function renewWithSignature(
        RenewRequest calldata request
    ) external payable {
        address signer = _verifyRenewRequest(request);

        require(
            hasRole(RENEW_ROLE, signer),
            "Signature invalid or unauthorized"
        );

        require(request.validUntil > block.timestamp, "Request expired");

        if (msg.value < request.price) {
            revert InsufficientValue();
        }

        bytes32 labelhash = keccak256(bytes(request.name));
        uint256 tokenId = uint256(labelhash);

        uint256 expires = nameWrapper.renew(tokenId, request.duration);

        emit NameRenewed(request.name, labelhash, request.price, expires);
    }

    function withdraw() public {
        payable(owner()).transfer(address(this).balance);
    }

    function supportsInterface(
        bytes4 interfaceID
    ) public view virtual override(IERC165, AccessControl) returns (bool) {
        return
            interfaceID == type(IERC165).interfaceId ||
            interfaceID == type(AccessControl).interfaceId;
    }

    /* Internal functions */

    function _setRecords(
        address resolverAddress,
        bytes32 label,
        bytes[] calldata data
    ) internal {
        // use hardcoded .base namehash
        bytes32 nodehash = keccak256(abi.encodePacked(ETH_NODE, label));
        Resolver resolver = Resolver(resolverAddress);
        resolver.multicallWithNodeCheck(nodehash, data);
    }

    function _setReverseRecord(
        string memory name,
        address resolver,
        address owner
    ) internal {
        reverseRegistrar.setNameForAddr(
            msg.sender,
            owner,
            resolver,
            string.concat(name, ".base")
        );
    }

    function _verifyRegisterRequest(
        RegisterRequest calldata request
    ) internal view returns (address) {
        bytes32 digest = _hashRegisterRequest(request);
        return ECDSA.recover(digest, request.signature);
    }

    function _hashRegisterRequest(
        RegisterRequest calldata request
    ) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "RegisterRequest(string name,address owner,uint256 duration,uint256 validUntil,address resolver,bool reverseRecord,uint16 ownerControlledFuses,uint256 price)"
                        ),
                        keccak256(bytes(request.name)),
                        request.owner,
                        request.duration,
                        request.validUntil,
                        request.resolver,
                        request.reverseRecord,
                        request.ownerControlledFuses,
                        request.price
                    )
                )
            );
    }

    function _verifyRenewRequest(
        RenewRequest calldata request
    ) internal view returns (address) {
        bytes32 digest = _hashRenewRequest(request);
        return ECDSA.recover(digest, request.signature);
    }

    function _hashRenewRequest(
        RenewRequest calldata request
    ) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "RenewRequest(string name,uint256 duration,uint256 validUntil,uint256 price)"
                        ),
                        keccak256(bytes(request.name)),
                        request.duration,
                        request.validUntil,
                        request.price
                    )
                )
            );
    }

    function getChainID() external view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function _checkNameAndDuration(
        string memory name,
        uint256 duration
    ) internal {
        if (!available(name)) {
            revert NameNotAvailable(name);
        }

        if (duration < MIN_REGISTRATION_DURATION) {
            revert DurationTooShort(duration);
        }
    }
}
