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

/**
 * @dev A registrar controller for registering and renewing names at fixed cost.
 */
contract RegistrarController is Ownable, ReverseClaimer {
    using StringUtils for *;
    using Address for address;

    struct DiscountDetails {
        bool active;
        uint256 duration;
        uint256 discount;
        address discountValidator;
    }

    function setDiscountDetails(bytes32 key, DiscountDetails memory details) external onlyOwner {
        discounts[key] = details;
    }

    BaseRegistrar immutable base;
    IPriceOracle public immutable prices;
    ReverseRegistrar public immutable reverseRegistrar;
    INameWrapper public immutable nameWrapper;
    mapping(bytes32 => DiscountDetails) public discounts;

    uint256 public constant MIN_REGISTRATION_DURATION = 28 days;
    bytes32 private constant ETH_NODE = 0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;
    uint64 private constant MAX_EXPIRY = type(uint64).max;

    error NameNotAvailable(string name);
    error DurationTooShort(uint256 duration);
    error ResolverRequiredWhenDataSupplied();
    error InactiveDiscount(bytes32 key);
    error InsufficientValue();
    error InvalidDiscount(bytes32 key, bytes data);
    error Unauthorised(bytes32 node);

    event NameRegistered(
        string name, bytes32 indexed label, address indexed owner, uint256 baseCost, uint256 premium, uint256 expires
    );
    event NameRenewed(string name, bytes32 indexed label, uint256 cost, uint256 expires);

    modifier validRegistration(string calldata name, uint256 duration, address resolver, bytes[] calldata data) {
        if (data.length > 0 && resolver == address(0)) {
            revert ResolverRequiredWhenDataSupplied();
        }
        if (!available(name)) {
            revert NameNotAvailable(name);
        }
        if (duration < MIN_REGISTRATION_DURATION) {
            revert DurationTooShort(duration);
        }
        _;
    }

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

    function rentPrice(string memory name, uint256 duration) public view returns (IPriceOracle.Price memory price) {
        bytes32 label = keccak256(bytes(name));
        price = prices.price(name, base.nameExpires(uint256(label)), duration);
    }

    function discountRentPrice(string memory name, uint256 duration, bytes32 discountKey)
        public
        view
        returns (IPriceOracle.Price memory price)
    {
        DiscountDetails memory details = discounts[discountKey];
        if(details.duration > 0) {
            price = rentPrice(name, details.duration);
        } else {
            price = rentPrice(name, duration);
        }

        // Prioritize discounting the base price
        if(price.base >= details.discount) {
            price.base -= details.discount;
        } else if(price.base + price.premium <= details.discount) {
            price.base = 0;
            price.premium = 0;
        } else { // base < discount < base+premium 
            price.premium -= (details.discount - price.base);
            price.base = 0;
        }
    }

    function valid(string memory name) public pure returns (bool) {
        return name.strlen() >= 3;
    }

    function available(string memory name) public view returns (bool) {
        bytes32 label = keccak256(bytes(name));
        return valid(name) && base.available(uint256(label));
    }

    function _validateAndApplyDiscount(
        bytes32 discountKey,
        bytes calldata validationData,
        string calldata name,
        uint256 duration
    ) internal returns (IPriceOracle.Price memory price) {
        DiscountDetails memory details = discounts[discountKey];

        if (!details.active) revert InactiveDiscount(discountKey);

        IDiscountValidator validator = IDiscountValidator(details.discountValidator);
        if (!validator.isValidDiscountRegistration(msg.sender, validationData)) {
            revert InvalidDiscount(discountKey, validationData);
        }

        price = discountRentPrice(name, duration, discountKey);
    }

    function discountedRegister(
        string calldata name,
        address owner,
        uint256 duration,
        address resolver,
        bytes[] calldata data,
        bool reverseRecord,
        bytes32 discountKey,
        bytes calldata validationData
    ) public payable validRegistration(name, duration, resolver, data) {
        IPriceOracle.Price memory price = _validateAndApplyDiscount(discountKey, validationData, name, duration);
        if (msg.value < price.base + price.premium) {
            revert InsufficientValue();
        }

        _register(name, owner, duration, resolver, data, reverseRecord, price);

        if (msg.value > (price.base + price.premium)) {
            payable(msg.sender).transfer(msg.value - (price.base + price.premium));
        }
    }

    function _register(
        string calldata name,
        address owner,
        uint256 duration,
        address resolver,
        bytes[] calldata data,
        bool reverseRecord,
        IPriceOracle.Price memory price
    ) internal {
        uint256 expires = nameWrapper.registerAndWrapETH2LD(name, owner, duration, resolver, uint16(0));

        if (data.length > 0) {
            _setRecords(resolver, keccak256(bytes(name)), data);
        }

        if (reverseRecord) {
            _setReverseRecord(name, resolver, msg.sender);
        }

        emit NameRegistered(name, keccak256(bytes(name)), owner, price.base, price.premium, expires);
    }

    function register(
        string calldata name,
        address owner,
        uint256 duration,
        address resolver,
        bytes[] calldata data,
        bool reverseRecord
    ) public payable validRegistration(name, duration, resolver, data) {
        IPriceOracle.Price memory price = rentPrice(name, duration);
        if (msg.value < price.base + price.premium) {
            revert InsufficientValue();
        }

        _register(name, owner, duration, resolver, data, reverseRecord, price);

        if (msg.value > (price.base + price.premium)) {
            payable(msg.sender).transfer(msg.value - (price.base + price.premium));
        }
    }

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
        payable(owner()).transfer(address(this).balance);
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
        // use hardcoded .eth namehash
        bytes32 nodehash = keccak256(abi.encodePacked(ETH_NODE, label));
        L2Resolver resolver = L2Resolver(resolverAddress);
        resolver.multicallWithNodeCheck(nodehash, data);
    }

    function _setReverseRecord(string memory name, address resolver, address owner) internal {
        reverseRegistrar.setNameForAddr(msg.sender, owner, resolver, string.concat(name, ".eth"));
    }
}
