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

    /// @notice A map of expiry times
    mapping(uint256 id => uint256 expiry) expiries;

    /// @notice The ENS registry
    ENS public ens;

    /// @notice The namehash of the TLD this registrar owns (eg, base.eth)
    bytes32 public baseNode;

    /// @notice A map of addresses that are authorised to register and renew names.
    mapping(address controller => bool isApproved) public controllers;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          CONSTANTS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice InterfaceId for the meta `supportsInterface` method
    bytes4 private constant INTERFACE_META_ID = bytes4(keccak256("supportsInterface(bytes4)"));

    /// @notice InterfaceId for IERC721
    bytes4 private constant ERC721_ID = bytes4(
        keccak256("balanceOf(address)") ^ keccak256("ownerOf(uint256)") ^ keccak256("approve(address,uint256)")
            ^ keccak256("getApproved(uint256)") ^ keccak256("setApprovalForAll(address,bool)")
            ^ keccak256("isApprovedForAll(address,address)") ^ keccak256("transferFrom(address,address,uint256)")
            ^ keccak256("safeTransferFrom(address,address,uint256)")
            ^ keccak256("safeTransferFrom(address,address,uint256,bytes)")
    );

    /// @notice InterfaceId for the Reclaim interface
    bytes4 private constant RECLAIM_ID = bytes4(keccak256("reclaim(uint256,address)"));

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          ERRORS                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Thrown when the name has expired.
    ///
    /// @param tokenId The id of the token that expired.
    error Expired(uint256 tokenId);

    /// @notice Thrown when called by an unauthorized owner.
    ///
    /// @param tokenId The id that was being called against.
    /// @param sender The unauthorized sender.
    error NotApprovedOwner(uint256 tokenId, address sender);

    /// @notice Thrown when the name is not available for registration.
    ///
    /// @param tokenId The id of the name that is not available.
    error NotAvailable(uint256 tokenId);

    /// @notice Thrown when the name is not registered or in its Grace Period.
    ///
    /// @param tokenId The id of the token that is not registered or in Grace Period.
    error NotRegisteredOrInGrace(uint256 tokenId);

    /// @notice Thrown when msg.sender is not an approved Controller.
    error OnlyController();

    /// @notice Thrown when this contract does not own the `baseNode`.
    error RegistrarNotLive();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          EVENTS                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Emitted when a Controller is added to the approved `controllers` mapping.
    ///
    /// @param controller The address of the approved controller.
    event ControllerAdded(address indexed controller);

    /// @notice Emitted when a Controller is removed from the approved `controllers` mapping.
    ///
    /// @param controller The address of the removed controller.
    event ControllerRemoved(address indexed controller);

    /// @notice Emitted when a name is registered.
    ///
    /// @param id The id of the registered name.
    /// @param owner The owner of the registered name.
    /// @param expires The expiry of the new ownership record.
    event NameRegistered(uint256 indexed id, address indexed owner, uint256 expires);

    /// @notice Emitted when a name is renewed.
    ///
    /// @param id The id of the renewed name.
    /// @param expires The new expiry for the name.
    event NameRenewed(uint256 indexed id, uint256 expires);

    /// @notice Emitted when a name is registered with ENS Records.
    ///
    /// @param id The id of the newly registered name.
    /// @param owner The owner of the registered name.
    /// @param expires The expiry of the new ownership record.
    /// @param resolver The address of the resolver for the name.
    /// @param ttl The time-to-live for the name.
    event NameRegisteredWithRecord(
        uint256 indexed id, address indexed owner, uint256 expires, address resolver, uint64 ttl
    );

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          MODIFIERS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Decorator for determining if the contract is actively managing registrations for its `baseNode`.
    modifier live() {
        if (ens.owner(baseNode) != address(this)) revert RegistrarNotLive();
        _;
    }

    /// @notice Decorator for restricting methods to only approved Controller callers.
    modifier onlyController() {
        if (!controllers[msg.sender]) revert OnlyController();
        _;
    }

    /// @notice Decorator for determining if a name is available.
    ///
    /// @param id The id being checked for availability.
    modifier onlyAvailable(uint256 id) {
        if (!isAvailable(id)) revert NotAvailable(id);
        _;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        IMPLEMENTATION                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice BaseRegistrar construcotr used to initialize the configuration of the implementation.
    ///
    /// @param ens_ The Registry contract.
    /// @param owner_ The permissioned address initialized as the `owner` in the `Ownable` context.
    /// @param baseNode_ The node that this contract manages registrations for.
    constructor(ENS ens_, address owner_, bytes32 baseNode_) {
        _initializeOwner(owner_);
        ens = ens_;
        baseNode = baseNode_;
    }

    /// @notice Authorises a controller, who can register and renew domains.
    ///
    /// @dev Emits `ControllerAdded(controller)` after adding the `controller` to the `controllers` mapping.
    ///
    /// @param controller The address of the new controller.
    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
        emit ControllerAdded(controller);
    }

    /// @notice Revoke controller permission for an address.
    ///
    /// @dev Emits `ControllerRemoved(controller)` after removing the `controller` from the `controllers` mapping.
    ///
    /// @param controller The address of the controller to remove.
    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
        emit ControllerRemoved(controller);
    }

    /// @notice Set the resolver for the node this registrar manages.
    ///
    /// @param resolver The address of the new resolver contract.
    function setResolver(address resolver) external onlyOwner {
        ens.setResolver(baseNode, resolver);
    }

    /// @notice Returns the expiration timestamp of the specified id.
    ///
    /// @param id The id of the name being checked.
    function nameExpires(uint256 id) external view returns (uint256) {
        return expiries[id];
    }

    /// @notice Register a name.
    ///
    /// @param id The token id determined by keccak256(label).
    /// @param owner The address that should own the registration.
    /// @param duration Duration in seconds for the registration.
    ///
    /// @return The expiry date of the registered name.
    function register(uint256 id, address owner, uint256 duration) external returns (uint256) {
        return _register(id, owner, duration, true);
    }

    /// @notice Register a name without modifying the Registry.
    ///
    /// @param id The token id determined by keccak256(label).
    /// @param owner The address that should own the registration.
    /// @param duration Duration in seconds for the registration.
    ///
    /// @return The expiry date of the registered name.
    function registerOnly(uint256 id, address owner, uint256 duration) external returns (uint256) {
        return _register(id, owner, duration, false);
    }

    /// @notice Register a name and add details to the record in the Registry.
    ///
    /// @dev This method can only be called if:
    ///         1. The contract is `live`
    ///         2. The caller is an approved `controller`
    ///         3. The name id is `available`
    ///     Emits `NameRegisteredWithRecord()` after successfully registering the name and setting the records.
    ///
    /// @param id The token id determined by keccak256(label).
    /// @param owner The address that should own the registration.
    /// @param duration Duration in seconds for the registration.
    /// @param resolver Address of the resolver for the name.
    /// @param ttl Time-to-live for the name.
    function registerWithRecord(uint256 id, address owner, uint256 duration, address resolver, uint64 ttl)
        external
        live
        onlyController
        onlyAvailable(id)
        returns (uint256)
    {
        uint256 expiry = _localRegister(id, owner, duration);
        ens.setSubnodeRecord(baseNode, bytes32(id), owner, resolver, ttl);
        emit NameRegisteredWithRecord(id, owner, expiry, resolver, ttl);
        return expiry;
    }

    /// @notice Gets the owner of the specified token ID.
    ///
    /// @dev Names become unowned when their registration expires.
    ///
    /// @param tokenId The id of the name to query the owner of.
    ///
    /// @return address The address currently marked as the owner of the given token ID.
    function ownerOf(uint256 tokenId) public view override returns (address) {
        if (expiries[tokenId] <= block.timestamp) revert Expired(tokenId);
        return super.ownerOf(tokenId);
    }

    /// @notice Returns true if the specified name is available for registration.
    ///
    /// @param id The id of the name to check availability of.
    ///
    /// @return `true` if the name is available, else `false`.
    function isAvailable(uint256 id) public view returns (bool) {
        // Not available if it's registered here or in its grace period.
        return expiries[id] + GRACE_PERIOD < block.timestamp;
    }

    /// @notice Allows holders of names to renew their ownerhsip and extend their expiry.
    ///
    /// @dev Renewal can be called while owning a subdomain or while the name is in the
    ///     grace period. Can only be called by a controller.
    ///     Emits `NameRenewed()` after renewing the name by updating the expiry.
    ///
    /// @param id The id of the name to renew.
    /// @param duration The time that will be added to this name's expiry.
    ///
    /// @return The new expiry date.
    function renew(uint256 id, uint256 duration) external live onlyController returns (uint256) {
        if (expiries[id] + GRACE_PERIOD < block.timestamp) revert NotRegisteredOrInGrace(id);

        expiries[id] += duration;
        emit NameRenewed(id, expiries[id]);
        return expiries[id];
    }

    /// @notice Reclaim ownership of a name in ENS, if you own it in the registrar.
    ///
    /// @dev Token transfers are ambiguous for determining name ownership transfers. This method exists so that
    ///     if a name token is transfered to a new owner, they have the right to claim ownership over their
    ///     name in the Registry.
    ///
    /// @param id The id of the name to reclaim.
    /// @param owner The address of the owner that will be set in the Registry.
    function reclaim(uint256 id, address owner) external live {
        if (!_isApprovedOrOwner(msg.sender, id)) revert NotApprovedOwner(id, owner);
        ens.setSubnodeOwner(baseNode, bytes32(id), owner);
    }

    /// @notice Register a name and possibly update the Registry.
    ///
    /// @dev This method can only be called if:
    ///         1. The contract is `live`
    ///         2. The caller is an approved `controller`
    ///         3. The name id is `available`
    ///     Emits `NameRegistered()` after successfully registering the name.
    ///
    /// @param id The token id determined by keccak256(label).
    /// @param owner The address that should own the registration.
    /// @param duration Duration in seconds for the registration.
    /// @param updateRegistry Whether to update the Regstiry with the ownership change
    ///
    /// @return The expiry date of the registered name.
    function _register(uint256 id, address owner, uint256 duration, bool updateRegistry)
        internal
        live
        onlyController
        onlyAvailable(id)
        returns (uint256)
    {
        uint256 expiry = _localRegister(id, owner, duration);
        if (updateRegistry) {
            ens.setSubnodeOwner(baseNode, bytes32(id), owner);
        }
        emit NameRegistered(id, owner, expiry);
        return expiry;
    }

    /// @notice Internal handler for local state changes during registrations.
    ///
    /// @dev Sets the token's expiry time and then `burn`s and `mint`s a new token.
    ///
    /// @param id The token id determined by keccak256(label).
    /// @param owner The address that should own the registration.
    /// @param duration Duration in seconds for the registration.
    ///
    /// @return expiry The expiry date of the registered name.
    function _localRegister(uint256 id, address owner, uint256 duration) internal returns (uint256 expiry) {
        expiry = block.timestamp + duration;
        expiries[id] = expiry;
        if (_exists(id)) {
            // Name was previously owned, and expired
            _burn(id);
        }
        _mint(owner, id);
    }

    /// @notice Returns whether the given spender can transfer a given token ID.abi
    ///
    /// @dev v2.1.3 version of _isApprovedOrOwner which calls ownerOf(tokenId) and takes grace period into consideration instead of ERC721.ownerOf(tokenId);
    /// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.1.3/contracts/token/ERC721/ERC721.sol#L187
    ///
    /// @param spender address of the spender to query
    /// @param tokenId uint256 ID of the token to be transferred
    ///
    /// @return `true` if msg.sender is approved for the given token ID, is an operator of the owner,
    ///         or is the owner of the token, else `false`.
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

    /// @notice ERC165 compliant signal for interface support.
    ///
    /// @dev Checks interface support for reclaim OR IERC721 OR ERC165
    ///     https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
    ///
    /// @param interfaceID the ERC165 iface id being checked for compliance
    ///
    /// @return bool Whether this contract supports the provided interfaceID
    function supportsInterface(bytes4 interfaceID) public pure override(ERC721) returns (bool) {
        return interfaceID == INTERFACE_META_ID || interfaceID == ERC721_ID || interfaceID == RECLAIM_ID;
    }
}
