// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {EnumerableSetLib} from "solady/utils/EnumerableSetLib.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {StringUtils} from "ens-contracts/ethregistrar/StringUtils.sol";

import {BASE_ETH_NODE} from "src/util/Constants.sol";
import {BaseRegistrar} from "./BaseRegistrar.sol";
import {IDiscountValidator} from "./interface/IDiscountValidator.sol";
import {IPriceOracle} from "./interface/IPriceOracle.sol";
import {L2Resolver} from "./L2Resolver.sol";
import {IReverseRegistrar} from "./interface/IReverseRegistrar.sol";

/**
 * @dev A registrar controller for registering and renewing names at fixed cost.
 */
contract RegistrarController is Ownable {
    using StringUtils for *;
    using SafeERC20 for IERC20;
    using EnumerableSetLib for EnumerableSetLib.Bytes32Set;

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
        uint256 discount; // denom in wei
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    BaseRegistrar immutable base;
    IPriceOracle public immutable prices;
    IReverseRegistrar public immutable reverseRegistrar;
    IERC20 public immutable usdc;
    EnumerableSetLib.Bytes32Set internal activeDiscounts;
    mapping(bytes32 => DiscountDetails) public discounts;
    mapping(address => bool) public discountedRegistrants;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          CONSTANTS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    uint256 public constant MIN_REGISTRATION_DURATION = 28 days;
    uint256 private constant MIN_NAME_LENGTH = 3;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          ERRORS                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    error AlreadyClaimedWithDiscount(address sender);
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
    event ETHPaymentProcessed(address indexed payee, uint256 price);
    event RegisteredWithDiscount(address indexed registrant, bytes32 indexed discountKey);
    event NameRegistered(string name, bytes32 indexed label, address indexed owner, uint256 expires);
    event NameRenewed(string name, bytes32 indexed label, uint256 expires);
    event DiscountUpdated(bytes32 indexed discountKey, DiscountDetails details);

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

    modifier validDiscount(bytes32 discountKey, bytes calldata validationData) {
        if (discountedRegistrants[msg.sender]) revert AlreadyClaimedWithDiscount(msg.sender);
        DiscountDetails memory details = discounts[discountKey];

        if (!details.active) revert InactiveDiscount(discountKey);

        IDiscountValidator validator = IDiscountValidator(details.discountValidator);
        if (!validator.isValidDiscountRegistration(msg.sender, validationData)) {
            revert InvalidDiscount(discountKey, validationData);
        }
        _;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        IMPLEMENTATION                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    constructor(
        BaseRegistrar base_,
        IPriceOracle prices_,
        IERC20 usdc_,
        IReverseRegistrar reverseRegistrar_,
        address owner_
    ) {
        base = base_;
        prices = prices_;
        usdc = usdc_;
        reverseRegistrar = reverseRegistrar_;
        _initializeOwner(owner_);
        // Assign ownership of this contract's reverse record to this contract's owner
        reverseRegistrar.claim(owner_);
    }

    function hasRegisteredWithDiscount(address[] memory addresses) public view returns (bool) {
        for (uint256 i; i < addresses.length; i++) {
            if (discountedRegistrants[addresses[i]]) {
                return true;
            }
        }
        return false;
    }

    function valid(string memory name) public pure returns (bool) {
        return name.strlen() >= MIN_NAME_LENGTH;
    }

    function available(string memory name) public view returns (bool) {
        bytes32 label = keccak256(bytes(name));
        return valid(name) && base.isAvailable(uint256(label));
    }

    function rentPrice(string memory name, uint256 duration) public view returns (IPriceOracle.Price memory price) {
        bytes32 label = keccak256(bytes(name));
        price = prices.price(name, base.nameExpires(uint256(label)), duration);
    }

    function registerPrice(string memory name, uint256 duration) public view returns (uint256) {
        IPriceOracle.Price memory price = rentPrice(name, duration);
        return price.base + price.premium;
    }

    function getActiveDiscounts() external view returns (DiscountDetails[] memory) {
        bytes32[] memory activeDiscountKeys = activeDiscounts.values();
        DiscountDetails[] memory activeDiscountDetails = new DiscountDetails[](activeDiscountKeys.length);
        for (uint256 i; i < activeDiscountKeys.length; i++) {
            activeDiscountDetails[i] = discounts[activeDiscountKeys[i]];
        }
        return activeDiscountDetails;
    }

    function setDiscountDetails(bytes32 key, DiscountDetails memory details) external onlyOwner {
        if (details.discount == 0) revert InvalidDiscountAmount(key, details.discount);
        if (details.discountValidator == address(0)) revert InvalidValidator(key, details.discountValidator);
        discounts[key] = details;
        _updateActiveDiscounts(key, details.active);
        emit DiscountUpdated(key, details);
    }

    function _updateActiveDiscounts(bytes32 key, bool active) internal {
        active ? activeDiscounts.add(key) : activeDiscounts.remove(key);
    }

    function discountRentPrice(string memory name, uint256 duration, bytes32 discountKey)
        public
        view
        returns (uint256 price)
    {
        DiscountDetails memory discount = discounts[discountKey];
        price = registerPrice(name, duration);
        price = (price >= discount.discount) ? price - discount.discount : 0;
    }

    function register(RegisterRequest calldata request) public payable validRegistration(request) {
        uint256 price = registerPrice(request.name, request.duration);

        _validatePayment(price);

        _register(request);

        _refundExcessEth(price);
    }

    function discountedRegister(RegisterRequest calldata request, bytes32 discountKey, bytes calldata validationData)
        public
        payable
        validDiscount(discountKey, validationData)
        validRegistration(request)
    {
        uint256 price = discountRentPrice(request.name, request.duration, discountKey);

        _validatePayment(price);

        _register(request);
        discountedRegistrants[msg.sender] = true;

        _refundExcessEth(price);

        emit RegisteredWithDiscount(msg.sender, discountKey);
    }

    function renew(string calldata name, uint256 duration) external payable {
        bytes32 labelhash = keccak256(bytes(name));
        uint256 tokenId = uint256(labelhash);
        IPriceOracle.Price memory price = rentPrice(name, duration);

        _validatePayment(price.base);

        uint256 expires = base.renew(tokenId, duration);

        _refundExcessEth(price.base);

        emit NameRenewed(name, labelhash, expires);
    }

    function _validatePayment(uint256 price) internal {
        if (msg.value < price) {
            revert InsufficientValue();
        }
        emit ETHPaymentProcessed(msg.sender, price);
    }

    function _register(RegisterRequest calldata request) internal {
        uint256 expires = base.registerWithRecord(
            uint256(keccak256(bytes(request.name))), request.owner, request.duration, request.resolver, 0
        );

        if (request.data.length > 0) {
            _setRecords(request.resolver, keccak256(bytes(request.name)), request.data);
        }

        if (request.reverseRecord) {
            _setReverseRecord(request.name, request.resolver, msg.sender);
        }

        emit NameRegistered(request.name, keccak256(bytes(request.name)), request.owner, expires);
    }

    function _refundExcessEth(uint256 price) internal {
        if (msg.value > price) {
            (bool sent,) = payable(msg.sender).call{value: (msg.value - price)}("");
            if (!sent) revert TransferFailed();
        }
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

    function withdrawETH() public {
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
        IERC20(_token).safeTransfer(_to, _amount);
    }
}
