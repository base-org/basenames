// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Address} from "lib/openzeppelin-contracts/contracts/utils/Address.sol";
import {ECDSA} from "solady/utils/ECDSA.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import {ENS} from "ens-contracts/registry/ENS.sol";
import {INameWrapper} from "ens-contracts/wrapper/INameWrapper.sol";
import {ReverseClaimer} from "ens-contracts/reverseRegistrar/ReverseClaimer.sol";
import {StringUtils} from "ens-contracts/ethregistrar/StringUtils.sol";

import {BaseRegistrar} from "./BaseRegistrar.sol";
import {IDiscountValidator} from "./interface/IDiscountValidator.sol";
import {IPriceOracle} from "./interface/IPriceOracle.sol";
import {ReverseRegistrar} from "./ReverseRegistrar.sol";
import {L2Resolver} from "./L2Resolver.sol";
import {BASE_ETH_NODE} from "src/util/Constants.sol";

// @TODO we need to add support for USDC
// @TODO add renew with discount flow
// @TODO emit discount claim event w/ type
// @TODO track discounted claims by address to ensure no double dipping
// @TODO active discounts
// @TODO ++ Availability state check

/**
 * @dev A registrar controller for registering and renewing names at fixed cost.
 */
contract RegistrarController is Ownable, ReverseClaimer {
    using StringUtils for *;
    using Address for address;
    using SafeERC20 for IERC20;

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
    IERC20 public immutable usdc;
    mapping(bytes32 => DiscountDetails) public discounts;
    DiscountDetails[] public activeDiscounts; // push or pop discounts, make queryable

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
    event USDCPaymentProcessed(address payee, uint256 price);
    event NameRegistered(string name, bytes32 indexed label, address indexed owner, uint256 expires);
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

    modifier validateDiscount(
        bytes32 discountKey,
        bytes calldata validationData
    ) {
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
        ReverseRegistrar reverseRegistrar_,
        INameWrapper nameWrapper_,
        ENS ens_
    ) ReverseClaimer(ens_, msg.sender) {
        base = base_;
        prices = prices_;
        usdc = usdc_;
        reverseRegistrar = reverseRegistrar_;
        nameWrapper = nameWrapper_;
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

    function registerPriceETH(string memory name, uint256 duration) public view returns (uint256) {
        IPriceOracle.Price memory price = rentPrice(name, duration);
        return price.base_wei + price.premium_wei;
    }

    function registerPriceUSDC(string memory name, uint256 duration) public view returns (uint256) {
        IPriceOracle.Price memory price = rentPrice(name, duration);
        return price.base_usdc + price.premium_usdc;
    }

    function setDiscountDetails(bytes32 key, DiscountDetails memory details) external onlyOwner {
        if (details.discount == 0) revert InvalidDiscountAmount(key, details.discount);
        if (details.discountValidator == address(0)) revert InvalidValidator(key, details.discountValidator);
        discounts[key] = details;
    }

    function discountRentPrice(string memory name, uint256 duration, bytes32 discountKey)
        public
        view
        returns (uint256 price_usdc)
    {
        DiscountDetails memory discount = discounts[discountKey];
        if (discount.duration > 0) {
            price_usdc = discount.duration >= duration
                ? registerPriceUSDC(name, 0)
                : registerPriceUSDC(name, duration - discount.duration);
        } else {
            price_usdc = registerPriceUSDC(name, duration);
        }

        price_usdc = (price_usdc >= discount.discount) ? price_usdc - discount.discount : 0;
    }

    function discountRentPriceETH(string memory name, uint256 duration, bytes32 discountKey)
        public
        view
        returns (uint256)
    {
        uint256 price_usdc = discountRentPrice(name, duration, discountKey);
        return prices.attoUSDToWei(price_usdc);
    }

    function discountedRegisterETH(
        RegisterRequest calldata request,
        uint16 ownerControlledFuses,
        bytes32 discountKey,
        bytes calldata validationData
    ) public payable validateDiscount(discountKey, validationData) validRegistration(request) {
        uint256 price_wei = discountRentPriceETH(request.name, request.duration, discountKey);
        _validateETHPayment(price_wei);
        _register(request, ownerControlledFuses);
        _refundExcessEth(price_wei);
    }

    function registerETH(RegisterRequest calldata request, uint16 ownerControlledFuses)
        public
        payable
        validRegistration(request)
    {
        uint256 price_wei = registerPriceETH(request.name, request.duration);
        _validateETHPayment(price_wei);
        _register(request, ownerControlledFuses);
        _refundExcessEth(price_wei);
    }

    function discountedRegisterUSDC(
        RegisterRequest calldata request,
        uint16 ownerControlledFuses,
        bytes32 discountKey,
        bytes calldata validationData
    ) public payable validateDiscount(discountKey, validationData) validRegistration(request) {
        uint256 price_usdc = discountRentPrice(request.name, request.duration, discountKey);
        _processUSDCPayment(price_usdc);
        _register(request, ownerControlledFuses);
    }

    function _validateETHPayment(uint256 price) internal {
        if (msg.value < price) {
            revert InsufficientValue();
        }
    }

    function _processUSDCPayment(uint256 price) internal {
        usdc.safeTransferFrom(msg.sender, address(this), price);
    }

    function registerUSDC(RegisterRequest calldata request, uint16 ownerControlledFuses)
        public
        payable
        validRegistration(request)
    {
        uint256 price = registerPriceUSDC(request.name, request.duration);
        _register(request, ownerControlledFuses);
        _refundExcessEth(price);
    }

    function _register(RegisterRequest calldata request, uint16 ownerControlledFuses) internal {
        uint256 expires = nameWrapper.registerAndWrapETH2LD(
            request.name, request.owner, request.duration, request.resolver, ownerControlledFuses
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

    // function renew(string calldata name, uint256 duration) external payable {
    //     bytes32 labelhash = keccak256(bytes(name));
    //     uint256 tokenId = uint256(labelhash);
    //     IPriceOracle.Price memory price = rentPrice(name, duration);
    //     if (msg.value < price.base) {
    //         revert InsufficientValue();
    //     }
    //     uint256 expires = nameWrapper.renew(tokenId, duration);

    //     if (msg.value > price.base) {
    //         payable(msg.sender).transfer(msg.value - price.base);
    //     }

    //     emit NameRenewed(name, labelhash, msg.value, expires);
    // }

    function withdrawETH() public {
        (bool sent,) = payable(owner()).call{value: (address(this).balance)}("");
        if (!sent) revert TransferFailed();
    }

    function withdrawUSDC() public {
        usdc.safeTransfer(owner(), usdc.balanceOf(address(this)));
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
