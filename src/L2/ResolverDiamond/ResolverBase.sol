// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Registry} from "src/L2/Registry.sol";

import {ResolverAuth} from "./ResolverAuth.sol";

library LibResolverBase {
    struct ResolverBaseStorage {
        address owner;
        Registry registry;
        mapping(address controller => bool approved) approvedControllers;
        mapping(bytes32 node => uint64 version) recordVersions;
        mapping(address owner => mapping(address operator => bool isApproved)) operators;
        mapping(address owner => mapping(bytes32 node => mapping(address delegate => bool isApproved))) tokenApprovals;
    }

    bytes32 constant RESOLVER_BASE_STORAGE_POS = keccak256("resolver.base.storage.position");
    
    function resolverBaseStorage() internal pure returns (ResolverBaseStorage storage $) {
        bytes32 pos = RESOLVER_BASE_STORAGE_POS;
        assembly {
            $.slot := pos
        }
    }
}

contract ResolverBase is ResolverAuth {
    
    /// @notice Thown when msg.sender tries to set itself as an operator.
    error CantSetSelfAsOperator();

    /// @notice Thrown when msg.sender tries to set itself as a delegate for one of its names.
    error CantSetSelfAsDelegate();

    event VersionChanged(bytes32 indexed node, uint64 newVersion);
    event ControllerUpdated(address indexed controller, bool approved);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Emitted when an operator is added or removed.
    ///
    /// @param owner The address of the owner of names.
    /// @param operator The address of the approved operator for the `owner`.
    /// @param approved Whether the `operator` is approved or not.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /// @notice Emitted when a delegate is approved or an approval is revoked.
    ///
    /// @param owner The address of the owner of the name.
    /// @param node The namehash of the name.
    /// @param delegate The address of the operator for the specified `node`.
    /// @param approved Whether the `delegate` is approved for the specified `node`.
    event Approved(address owner, bytes32 indexed node, address indexed delegate, bool indexed approved);

    function setControllerApproved(address controller, bool approved) external isOwner {
        ResolverBaseStorage storage s = resolverBaseStorage();
        s.approvedControllers[controller] = approved;
        emit ControllerUpdated(controller, approved);
    }

    /// @dev See {IERC1155-setApprovalForAll}.
    function setApprovalForAll(address operator, bool approved) external {
        ResolverBaseStorage storage s = resolverBaseStorage();
        s.operators[msg.sender][operator] = approved;
    }

    /// @dev See {IERC1155-isApprovedForAll}.
    function isApprovedForAll(address account, address operator) public view returns (bool) {
        ResolverBaseStorage storage s = resolverBaseStorage();
        return s.operators[account][operator];
    }

    /// @notice Modify the permissions for a specified `delegate` for the specified `node`.
    ///
    /// @dev This method only sets the approval status for msg.sender's nodes. This is performed without checking
    ///     the ownership of the specified `node`.
    ///
    /// @param node The namehash `node` whose permissions are being updated.
    /// @param delegate The address of the `delegate`
    /// @param approved Whether the `delegate` has approval to modify records for `msg.sender`'s `node`.
    function approve(bytes32 node, address delegate, bool approved) external {
        ResolverBaseStorage storage s = resolverBaseStorage();
        if (msg.sender == delegate) revert CantSetSelfAsDelegate();

        s.tokenApprovals[msg.sender][node][delegate] = approved;
        emit Approved(msg.sender, node, delegate, approved);
    }

    /// @notice Check to see if the `delegate` has been approved by the `owner` for the `node`.
    ///
    /// @param owner The address of the name owner.
    /// @param node The namehash `node` whose permissions are being checked.
    /// @param delegate The address of the `delegate` whose permissions are being checked.
    ///
    /// @return `true` if `delegate` is approved to modify `msg.sender`'s `node`, else `false`.
    function isApprovedFor(address owner, bytes32 node, address delegate) public view returns (bool) {
        ResolverBaseStorage storage s = resolverBaseStorage();
        return s.tokenApprovals[owner][node][delegate];
    }

    /**
     * Increments the record version associated with a node.
     * May only be called by the owner of that node in the registry.
     * @param node The node to update.
     */
    function clearRecords(bytes32 node) public isAuthorized(node) {
        ResolverBaseStorage storage s = resolverBaseStorage();
        s.recordVersions[node]++;
        emit VersionChanged(node, s.recordVersions[node]);
    }

    function _isAuthorized(bytes32 node, address caller) internal view returns (bool) {
        ResolverBaseStorage storage s = resolverBaseStorage();
        if (s.approvedControllers[caller]) {
            return true;
        }
        address owner = s.registry.owner(node);
        return owner == msg.sender || s.operators[owner][caller] || s.tokenApprovals[owner][node][caller];
    }

    function setContractOwner(address _newOwner) internal {
        ResolverBaseStorage storage s = resolverBaseStorage();
        address previousOwner = s.contractOwner;
        s.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = resolverBaseStorage().contractOwner;
    }

    function isContractOwner() internal view returns (bool) {
        return (msg.sender == resolverBaseStorage().contractOwner);
    }
}
