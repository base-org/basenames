// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ENS} from "ens-contracts/registry/ENS.sol";
import {ERC721} from "lib/solady/src/tokens/ERC721.sol";
import {Ownable} from "solady/auth/Ownable.sol";

import {BASE_ETH_NODE} from "src/util/Constants.sol";

contract BaseRegistrar is ERC721, Ownable {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    // A map of expiry times
    mapping(uint256 => uint256) expiries;
    // The ENS registry
    ENS public ens;
    // A map of addresses that are authorised to register and renew names.
    mapping(address => bool) public controllers;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          CONSTANTS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    uint256 public constant GRACE_PERIOD = 90 days;
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

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          MODIFIERS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    modifier live() {
        if (ens.owner(BASE_ETH_NODE) != address(this)) revert RegistrarNotLive();
        _;
    }

    modifier onlyController() {
        if (!controllers[msg.sender]) revert OnlyController();
        _;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        IMPLEMENTATION                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    constructor(ENS _ens, address _owner) {
        _initializeOwner(_owner);
        ens = _ens;
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
        ens.setResolver(BASE_ETH_NODE, resolver);
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
    function ownerOf(uint256 tokenId) public view override(ERC721) returns (address) {
        if (expiries[tokenId] <= block.timestamp) revert Expired(tokenId);
        return super.ownerOf(tokenId);
    }

    // Returns true iff the specified name is available for registration.
    function available(uint256 id) public view returns (bool) {
        // Not available if it's registered here or in its grace period.
        return expiries[id] + GRACE_PERIOD < block.timestamp;
    }

    function renew(uint256 id, uint256 duration) external live onlyController returns (uint256) {
        if (expiries[id] + GRACE_PERIOD < block.timestamp) revert NotRegisteredOrInGrace(id); // Name must be registered here or in grace period

        expiries[id] += duration;
        emit NameRenewed(id, expiries[id]);
        return expiries[id];
    }

    /**
     * @dev Reclaim ownership of a name in ENS, if you own it in the registrar.
     */
    function reclaim(uint256 id, address owner) external live {
        if (!_isApprovedOrOwner(msg.sender, id)) revert NotApprovedOwner(id, owner);
        ens.setSubnodeOwner(BASE_ETH_NODE, bytes32(id), owner);
    }

    function _register(uint256 id, address owner, uint256 duration, bool updateRegistry)
        internal
        live
        onlyController
        returns (uint256)
    {
        if (!available(id)) revert NotAvailable(id);

        expiries[id] = block.timestamp + duration;
        if (_exists(id)) {
            // Name was previously owned, and expired
            _burn(id);
        }
        _mint(owner, id);
        if (updateRegistry) {
            ens.setSubnodeOwner(BASE_ETH_NODE, bytes32(id), owner);
        }

        emit NameRegistered(id, owner, block.timestamp + duration);

        return block.timestamp + duration;
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
