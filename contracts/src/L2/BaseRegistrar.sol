// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ENS} from "ens-contracts/registry/ENS.sol";
import {ERC721} from "lib/solady/src/tokens/ERC721.sol";
import {Ownable} from "solady/auth/Ownable.sol";

import {GRACE_PERIOD} from "src/util/Constants.sol";

/// @title Base Registrar
///
/// @notice The base-level tokenization contract for an ens domain. The Base Registrar implements ERC721 and, as the owner
///         of a 2LD, can mint and assign ownership rights to its subdomains. I.e. This contract owns "base.eth" and allows
///         users to mint subdomains like "vitalik.base.eth". Registration is delegated to "controller" contracts which have
///         rights to call `onlyController` protected methods.
///
///         The implementation is heavily inspired by the original ENS BaseRegistrarImplementation contract:
///         https://github.com/ensdomains/ens-contracts/blob/staging/contracts/ethregistrar/BaseRegistrarImplementation.sol
///
/// @author Coinbase (https://github.com/base-org/usernames)
contract BaseRegistrar is ERC721, Ownable {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    // A map of expiry times
    mapping(uint256 id => uint256 expiry) expiries;
    // The ENS registry
    ENS public ens;
    // The namehash of the TLD this registrar owns (eg, .eth)
    bytes32 public baseNode;
    // A map of addresses that are authorised to register and renew names.
    mapping(address controller => bool isApproved) public controllers;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          CONSTANTS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    bytes4 private constant INTERFACE_META_ID = bytes4(keccak256("supportsInterface(bytes4)"));
    bytes4 private constant ERC721_ID = bytes4(
        keccak256("balanceOf(address)") ^ keccak256("ownerOf(uint256)") ^ keccak256("approve(address,uint256)")
            ^ keccak256("getApproved(uint256)") ^ keccak256("setApprovalForAll(address,bool)")
            ^ keccak256("isApprovedForAll(address,address)") ^ keccak256("transferFrom(address,address,uint256)")
            ^ keccak256("safeTransferFrom(address,address,uint256)")
            ^ keccak256("safeTransferFrom(address,address,uint256,bytes)")
    );
    bytes4 private constant RECLAIM_ID = bytes4(keccak256("reclaim(uint256,address)"));

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          ERRORS                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    error Expired(uint256 tokenId);
    error NotApprovedOwner(uint256 tokenId, address sender);
    error NotAvailable(uint256 tokenId);
    error NotRegisteredOrInGrace(uint256 tokenId);
    error OnlyController();
    error RegistrarNotLive();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          EVENTS                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    event ControllerAdded(address indexed controller);
    event ControllerRemoved(address indexed controller);
    event NameMigrated(uint256 indexed id, address indexed owner, uint256 expires);
    event NameRegistered(uint256 indexed id, address indexed owner, uint256 expires);
    event NameRenewed(uint256 indexed id, uint256 expires);
    event NameRegisteredWithRecord(
        uint256 indexed id, address indexed owner, uint256 expires, address resolver, uint64 ttl
    );

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          MODIFIERS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    modifier live() {
        if (ens.owner(baseNode) != address(this)) revert RegistrarNotLive();
        _;
    }

    modifier onlyController() {
        if (!controllers[msg.sender]) revert OnlyController();
        _;
    }

    modifier isAvailable(uint256 id) {
        if (!available(id)) revert NotAvailable(id);
        _;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        IMPLEMENTATION                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    constructor(ENS ens_, address owner_, bytes32 baseNode_) {
        _initializeOwner(owner_);
        ens = ens_;
        baseNode = baseNode_;
    }

    // Authorises a controller, who can register and renew domains.
    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
        emit ControllerAdded(controller);
    }

    // Revoke controller permission for an address.
    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
        emit ControllerRemoved(controller);
    }

    // Set the resolver for the TLD this registrar manages.
    function setResolver(address resolver) external onlyOwner {
        ens.setResolver(baseNode, resolver);
    }

    // Returns the expiration timestamp of the specified id.
    function nameExpires(uint256 id) external view returns (uint256) {
        return expiries[id];
    }

    /**
     * @dev Register a name.
     * @param id The token ID (keccak256 of the label).
     * @param owner The address that should own the registration.
     * @param duration Duration in seconds for the registration.
     */
    function register(uint256 id, address owner, uint256 duration) external returns (uint256) {
        return _register(id, owner, duration, true);
    }

    /**
     * @dev Register a name and add details to the record in the Registry.
     * @param id The token ID (keccak256 of the label).
     * @param owner The address that should own the registration.
     * @param duration Duration in seconds for the registration.
     * @param resolver Address of the resolver for the name
     * @param ttl time-to-live for the name
     */
    function registerWithRecord(uint256 id, address owner, uint256 duration, address resolver, uint64 ttl)
        external
        returns (uint256)
    {
        return _registerWithRecord(id, owner, duration, resolver, ttl);
    }

    /**
     * @dev Register a name, without modifying the registry.
     * @param id The token ID (keccak256 of the label).
     * @param owner The address that should own the registration.
     * @param duration Duration in seconds for the registration.
     */
    function registerOnly(uint256 id, address owner, uint256 duration) external returns (uint256) {
        return _register(id, owner, duration, false);
    }

    /**
     * @dev Gets the owner of the specified token ID. Names become unowned
     *      when their registration expires.
     * @param tokenId uint256 ID of the token to query the owner of
     * @return address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        if (expiries[tokenId] <= block.timestamp) revert Expired(tokenId);
        return super.ownerOf(tokenId);
    }

    // Returns true iff the specified name is available for registration.
    function available(uint256 id) public view returns (bool) {
        // Not available if it's registered here or in its grace period.
        return expiries[id] + GRACE_PERIOD < block.timestamp;
    }

    /// @notice Allows holders of names can renew their ownerhsip and extend their expiry
    ///
    /// @dev Renewal can be called while owning a subdomain or while the name is in the
    /// @dev grace period. Can only be called by a controller.
    ///
    /// @param id The Id to renew
    /// @param duration The time that will be added to this name's expiry
    ///
    /// @return The new expiry date
    function renew(uint256 id, uint256 duration) external live onlyController returns (uint256) {
        if (expiries[id] + GRACE_PERIOD < block.timestamp) revert NotRegisteredOrInGrace(id);

        expiries[id] += duration;
        emit NameRenewed(id, expiries[id]);
        return expiries[id];
    }

    /**
     * @dev Reclaim ownership of a name in ENS, if you own it in the registrar.
     */
    function reclaim(uint256 id, address owner) external live {
        if (!_isApprovedOrOwner(msg.sender, id)) revert NotApprovedOwner(id, owner);
        ens.setSubnodeOwner(baseNode, bytes32(id), owner);
    }

    function _internalRegister(uint256 id, address owner, uint256 duration) internal returns (uint256 expiry) {
        expiry = block.timestamp + duration;
        expiries[id] = expiry;
        if (_exists(id)) {
            // Name was previously owned, and expired
            _burn(id);
        }
        _mint(owner, id);
    }

    function _register(uint256 id, address owner, uint256 duration, bool updateRegistry)
        internal
        live
        onlyController
        isAvailable(id)
        returns (uint256)
    {
        uint256 expiry = _internalRegister(id, owner, duration);
        if (updateRegistry) {
            ens.setSubnodeOwner(baseNode, bytes32(id), owner);
        }
        emit NameRegistered(id, owner, expiry);
        return expiry;
    }

    function _registerWithRecord(uint256 id, address owner, uint256 duration, address resolver, uint64 ttl)
        internal
        live
        onlyController
        isAvailable(id)
        returns (uint256)
    {
        uint256 expiry = _internalRegister(id, owner, duration);
        ens.setSubnodeRecord(baseNode, bytes32(id), owner, resolver, ttl);
        emit NameRegisteredWithRecord(id, owner, expiry, resolver, ttl);
        return expiry;
    }

    /**
     * v2.1.3 version of _isApprovedOrOwner which calls ownerOf(tokenId) and takes grace period into consideration instead of ERC721.ownerOf(tokenId);
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.1.3/contracts/token/ERC721/ERC721.sol#L187
     * @dev Returns whether the given spender can transfer a given token ID
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     *    is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view override returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ERC721 METADATA                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the token collection name.
    function name() public pure override returns (string memory) {
        return "";
    }

    /// @dev Returns the token collection symbol.
    function symbol() public pure override returns (string memory) {
        return "";
    }

    /// @dev Returns the Uniform Resource Identifier (URI) for token `id`.
    function tokenURI(uint256) public pure override returns (string memory) {
        return "";
    }

    function supportsInterface(bytes4 interfaceID) public pure override(ERC721) returns (bool) {
        return interfaceID == INTERFACE_META_ID || interfaceID == ERC721_ID || interfaceID == RECLAIM_ID;
    }
}
