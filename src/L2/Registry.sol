// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ENS} from "ens-contracts/registry/ENS.sol";

/// @title Registry
///
/// @notice Inspired by the ENS Registry contract.
///         https://github.com/ensdomains/ens-contracts/blob/staging/contracts/registry/ENSRegistry.sol
///         Stores names as `nodes` in a flat structure. Each registered `node` is assigned a `Record` struct.
///
/// @author Coinbase (https://github.com/base-org/usernames)
/// @author ENS (https://github.com/ensdomains/ens-contracts/tree/staging)
contract Registry is ENS {
    /// @notice Structure for storing records on a per-node basis.
    struct Record {
        /// @dev Tracks the owner of the node.
        address owner;
        /// @dev Tracks the address of the resolver for that node.
        address resolver;
        /// @dev The time-to-live for the node.
        uint64 ttl;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice The storage of `Record` structs per `node`.
    mapping(bytes32 node => Record record) internal _records;

    /// @notice Storage for approved operators on a per-holder basis.
    mapping(address nameHolder => mapping(address operator => bool isApproved)) internal _operators;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          ERRORS                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Thrown when the caller is not the owner or operator for a node.
    error Unauthorized();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          MODIFIERS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Decorator for permitting modifications only by the owner or operator of the specified node.
    ///
    /// @param node The node to check authorization approval for.
    modifier authorized(bytes32 node) {
        address owner_ = _records[node].owner;
        if (owner_ != msg.sender && !_operators[owner_][msg.sender]) revert Unauthorized();
        _;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        IMPLEMENTATION                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Constructs a new Registry with the `rootOwner` as the permissioned address for managing establishing
    ///         TLD namespaces.
    ///
    /// @param rootOwner The address that can establish new TLDs.
    constructor(address rootOwner) {
        _records[0x0].owner = rootOwner;
    }

    /// @notice Sets the record for a node.
    ///
    /// @param node The node to update.
    /// @param owner_ The address of the new owner.
    /// @param resolver_ The address of the resolver.
    /// @param ttl_ The TTL in seconds.
    function setRecord(bytes32 node, address owner_, address resolver_, uint64 ttl_) external virtual override {
        setOwner(node, owner_);
        _setResolverAndTTL(node, resolver_, ttl_);
    }

    /// @notice Sets the record for a subnode.
    ///
    /// @param node The parent node.
    /// @param label The hash of the label specifying the subnode.
    /// @param owner_ The address of the new owner.
    /// @param resolver_ The address of the resolver.
    /// @param ttl_ The TTL in seconds.
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner_, address resolver_, uint64 ttl_)
        external
        virtual
        override
    {
        bytes32 subnode = setSubnodeOwner(node, label, owner_);
        _setResolverAndTTL(subnode, resolver_, ttl_);
    }

    /// @notice Transfers ownership of a node to a new address.
    ///
    /// @dev May only be called by the current owner or operator of the node.
    ///
    /// @param node The node to transfer ownership of.
    /// @param owner_ The address of the new owner.
    function setOwner(bytes32 node, address owner_) public virtual override authorized(node) {
        _setOwner(node, owner_);
        emit Transfer(node, owner_);
    }

    /// @notice Transfers ownership of a subnode to a new address.
    ///
    /// @dev Subnode is determined by keccak256(node, label).
    ///      May only be called by the owner of the parent node.
    ///
    /// @param node The parent node.
    /// @param label The hash of the label specifying the subnode.
    /// @param owner_ The address of the new owner.
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner_)
        public
        virtual
        override
        authorized(node)
        returns (bytes32)
    {
        bytes32 subnode = keccak256(abi.encodePacked(node, label));
        _setOwner(subnode, owner_);
        emit NewOwner(node, label, owner_);
        return subnode;
    }

    /// @notice Sets the resolver address for the specified node.
    ///
    /// @dev May only be called by the current owner or operator of the node.
    ///
    /// @param node The node to update.
    /// @param resolver_ The address of the resolver.
    function setResolver(bytes32 node, address resolver_) public virtual override authorized(node) {
        _records[node].resolver = resolver_;
        emit NewResolver(node, resolver_);
    }

    /// @notice Sets the TTL for the specified node.
    ///
    /// @dev May only be called by the current owner or operator of the node.
    ///
    /// @param node The node to update.
    /// @param ttl_ The TTL in seconds.
    function setTTL(bytes32 node, uint64 ttl_) public virtual override authorized(node) {
        _records[node].ttl = ttl_;
        emit NewTTL(node, ttl_);
    }

    /// @notice Set `operator`'s approval status for msg.sender.
    ///
    /// @dev Enable or disable approval for a third party ("operator") to manage
    ///     all of `msg.sender`'s ENS records. Emits the `ApprovalForAll()` event.
    ///
    /// @param operator Address to add to the set of authorized operators.
    /// @param approved True if the operator is approved, false to revoke approval.
    function setApprovalForAll(address operator, bool approved) external virtual override {
        _operators[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice Returns the address that owns the specified node.
    ///
    /// @param node The specified node.
    ///
    /// @return The address for the specified node if one is set, returns address(0) if this contract is owner.
    function owner(bytes32 node) public view virtual override returns (address) {
        address addr = _records[node].owner;
        if (addr == address(this)) {
            return address(0);
        }
        return addr;
    }

    /// @notice Returns the address of the resolver for the specified node.
    ///
    /// @param node The specified node.
    ///
    /// @return The address of the resolver.
    function resolver(bytes32 node) public view virtual override returns (address) {
        return _records[node].resolver;
    }

    /// @notice Returns the TTL of a node.
    ///
    /// @param node The specified node.
    ///
    /// @return The ttl of the node.
    function ttl(bytes32 node) public view virtual override returns (uint64) {
        return _records[node].ttl;
    }

    /// @notice Returns whether a record exists in this registry.
    ///
    /// @param node The specified node.
    ///
    /// @return `true` if a record exists, else `false`.
    function recordExists(bytes32 node) public view virtual override returns (bool) {
        return _records[node].owner != address(0x0);
    }

    /// @notice Query if an address is an authorized operator for another address.
    ///
    /// @param owner_ The address that owns the records.
    /// @param operator The address that acts on behalf of the owner.
    ///
    /// @return `true` if `operator` is an approved operator for `owner`, else `fase`.
    function isApprovedForAll(address owner_, address operator) external view virtual override returns (bool) {
        return _operators[owner_][operator];
    }

    /// @notice Set the owner in storage.
    ///
    /// @param node The specified node.
    /// @param owner_  The owner to store for that node.
    function _setOwner(bytes32 node, address owner_) internal virtual {
        _records[node].owner = owner_;
    }

    /// @notice Set the resolver and ttl in storage.
    ///
    /// @param node The spcified node.
    /// @param resolver_ The address of the resolver.
    /// @param ttl_ The TTL in seconds.
    function _setResolverAndTTL(bytes32 node, address resolver_, uint64 ttl_) internal {
        if (resolver_ != _records[node].resolver) {
            _records[node].resolver = resolver_;
            emit NewResolver(node, resolver_);
        }

        if (ttl_ != _records[node].ttl) {
            _records[node].ttl = ttl_;
            emit NewTTL(node, ttl_);
        }
    }
}
