// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Address} from "lib/openzeppelin-contracts/contracts/utils/Address.sol";
import {ECDSA} from "solady/utils/ECDSA.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {ERC20} from "solady/tokens/ERC20.sol";

import {ENS} from "ens-contracts/registry/ENS.sol";
import {INameWrapper} from "ens-contracts/wrapper/INameWrapper.sol";
import {IPriceOracle} from "ens-contracts/ethregistrar/IPriceOracle.sol";
import {ReverseClaimer} from "ens-contracts/reverseRegistrar/ReverseClaimer.sol";
import {StringUtils} from "ens-contracts/ethregistrar/StringUtils.sol";

import {BaseRegistrar} from "./BaseRegistrar.sol";
import {IDiscountValidator} from "./interface/IDiscountValidator.sol";
import {ReverseRegistrar} from "./ReverseRegistrar.sol";
import {L2Resolver} from "./L2Resolver.sol";
import {BASE_ETH_NODE} from "src/util/Constants.sol";

// @TODO we need to add support for USDC

/**
 * @dev A registrar controller for registering and renewing names at fixed cost.
 */
contract RegistrarController is Ownable, ReverseClaimer {
    using StringUtils for *;
    using Address for address;

    struct RegisterRequest {
        string name;
        address owner;
        uint256 duration;
        address resolver;
        bytes[] data;
        bool reverseRecord;
    }

    struct DiscountDetails {
        bool active;
        address discountValidator;
        uint256 duration; // duration of discount (subtracted from RegisterRequest duration)
        uint256 discount; // denom in dollars
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    BaseRegistrar immutable base;
    IPriceOracle public immutable prices;
    ReverseRegistrar public immutable reverseRegistrar;
    INameWrapper public immutable nameWrapper;
    mapping(bytes32 => DiscountDetails) public discounts;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          CONSTANTS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    uint256 public constant MIN_REGISTRATION_DURATION = 28 days;
    uint256 private constant MIN_NAME_LENGTH = 3;
    uint64 private constant MAX_EXPIRY = type(uint64).max;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          ERRORS                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    error NameNotAvailable(string name);
    error DurationTooShort(uint256 duration);
    error ResolverRequiredWhenDataSupplied();
    error InactiveDiscount(bytes32 key);
    error InsufficientValue();
    error InvalidDiscount(bytes32 key, bytes data);
    error InvalidDiscountAmount(bytes32 key, uint256 amount);
    error InvalidValidator(bytes32 key, address validator);
    error TransferFailed();
    error Unauthorised(bytes32 node);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          EVENTS                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    event NameRegistered(string name, bytes32 indexed label, address indexed owner, uint256 price, uint256 expires);
    event NameRenewed(string name, bytes32 indexed label, uint256 cost, uint256 expires);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          MODIFIERS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    modifier validRegistration(RegisterRequest calldata request) {
        if (request.data.length > 0 && request.resolver == address(0)) {
            revert ResolverRequiredWhenDataSupplied();
        }
        if (!available(request.name)) {
            revert NameNotAvailable(request.name);
        }
        if (request.duration < MIN_REGISTRATION_DURATION) {
            revert DurationTooShort(request.duration);
        }
        _;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        IMPLEMENTATION                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    constructor(
        BaseRegistrar _base,
        IPriceOracle _prices,
        ReverseRegistrar _reverseRegistrar,
        INameWrapper _nameWrapper,
        ENS _ens
    ) ReverseClaimer(_ens, msg.sender) {
        base = _base;
        prices = _prices;
        reverseRegistrar = _reverseRegistrar;
        nameWrapper = _nameWrapper;
    }

    function valid(string memory name) public pure returns (bool) {
        return name.strlen() >= MIN_NAME_LENGTH;
    }

    function available(string memory name) public view returns (bool) {
        bytes32 label = keccak256(bytes(name));
        return valid(name) && base.available(uint256(label));
    }

    function rentPrice(string memory name, uint256 duration) public view returns (IPriceOracle.Price memory price) {
        bytes32 label = keccak256(bytes(name));
        price = prices.price(name, base.nameExpires(uint256(label)), duration);
    }

    function registerPrice(string memory name, uint256 duration) public view returns (uint256) {
        IPriceOracle.Price memory price = rentPrice(name, duration);
        return price.base + price.premium;
    }

    function setDiscountDetails(bytes32 key, DiscountDetails memory details) external onlyOwner {
        if (details.discount == 0) revert InvalidDiscountAmount(key, details.discount);
        if (details.discountValidator == address(0)) revert InvalidValidator(key, details.discountValidator);
        discounts[key] = details;
    }

    function discountRentPrice(string memory name, uint256 duration, bytes32 discountKey)
        public
        view
        returns (uint256 price)
    {

        DiscountDetails memory details = discounts[discountKey];
        if (details.duration > 0) {
            price = details.duration >= duration ? 
                registerPrice(name, 0) :
                registerPrice(name, duration - details.duration);
        } else {
            price = registerPrice(name, duration);
        }

        price = (price >= details.discount) ?
            price - details.discount : 
            0;
    }

    function _validateAndApplyDiscount(
        bytes32 discountKey,
        bytes calldata validationData,
        string calldata name,
        uint256 duration
    ) internal returns (uint256 price) {
        DiscountDetails memory details = discounts[discountKey];

        if (!details.active) revert InactiveDiscount(discountKey);

        IDiscountValidator validator = IDiscountValidator(details.discountValidator);
        if (!validator.isValidDiscountRegistration(msg.sender, validationData)) {
            revert InvalidDiscount(discountKey, validationData);
        }

        price = discountRentPrice(name, duration, discountKey);
    }

    function discountedRegister(
        RegisterRequest calldata request,
        uint16 ownerControlledFuses,
        bytes32 discountKey,
        bytes calldata validationData
    ) public payable validRegistration(request) {
        uint256 price = _validateAndApplyDiscount(discountKey, validationData, request.name, request.duration);
        _register(request, ownerControlledFuses, price);
    }

    function register(RegisterRequest calldata request, uint16 ownerControlledFuses)
        public
        payable
        validRegistration(request)
    {
        uint256 price = registerPrice(request.name, request.duration);
        _register(request, ownerControlledFuses, price);
    }

    function _register(RegisterRequest calldata request, uint16 ownerControlledFuses, uint256 price) internal {
        if (msg.value < price) {
            revert InsufficientValue();
        }

        uint256 expires = nameWrapper.registerAndWrapETH2LD(
            request.name, request.owner, request.duration, request.resolver, ownerControlledFuses
        );

        if (request.data.length > 0) {
            _setRecords(request.resolver, keccak256(bytes(request.name)), request.data);
        }

        if (request.reverseRecord) {
            _setReverseRecord(request.name, request.resolver, msg.sender);
        }

        emit NameRegistered(request.name, keccak256(bytes(request.name)), request.owner, price, expires);

        if (msg.value > price) {
            (bool sent,) = payable(msg.sender).call{value: (msg.value - price)}("");
            if (!sent) revert TransferFailed();
        }
    }

    //@TODO add renew with discount flow 

    function renew(string calldata name, uint256 duration) external payable {
        bytes32 labelhash = keccak256(bytes(name));
        uint256 tokenId = uint256(labelhash);
        IPriceOracle.Price memory price = rentPrice(name, duration);
        if (msg.value < price.base) {
            revert InsufficientValue();
        }
        uint256 expires = nameWrapper.renew(tokenId, duration);

        if (msg.value > price.base) {
            payable(msg.sender).transfer(msg.value - price.base);
        }

        emit NameRenewed(name, labelhash, msg.value, expires);
    }

    function withdraw() public {
        (bool sent,) = payable(owner()).call{value: (address(this).balance)}("");
        if (!sent) revert TransferFailed();
    }

    /**
     * @notice Recover ERC20 tokens sent to the contract by mistake.
     * @param _to The address to send the tokens to.
     * @param _token The address of the ERC20 token to recover
     * @param _amount The amount of tokens to recover.
     */
    function recoverFunds(address _token, address _to, uint256 _amount) external onlyOwner {
        ERC20(_token).transfer(_to, _amount);
    }

    function _setRecords(address resolverAddress, bytes32 label, bytes[] calldata data) internal {
        // use hardcoded base.eth namehash
        bytes32 nodehash = keccak256(abi.encodePacked(BASE_ETH_NODE, label));
        L2Resolver resolver = L2Resolver(resolverAddress);
        resolver.multicallWithNodeCheck(nodehash, data);
    }

    function _setReverseRecord(string memory name, address resolver, address owner) internal {
        reverseRegistrar.setNameForAddr(msg.sender, owner, resolver, string.concat(name, ".base.eth"));
    }
}
