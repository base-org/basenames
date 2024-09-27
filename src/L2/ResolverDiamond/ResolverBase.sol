// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {LibResolverBase} from "./storage/LibResolverBase.sol";

contract ResolverBase {
    /// @notice Thown when msg.sender tries to set itself as an operator.
    error CantSetSelfAsOperator();

    /// @notice Thrown when msg.sender tries to set itself as a delegate for one of its names.
    error CantSetSelfAsDelegate();

    event VersionChanged(bytes32 indexed node, uint64 newVersion);
    event ControllerUpdated(address indexed controller, bool approved);

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


    function setControllerApproved(address controller, bool approved) external LibResolverBase.isOwner {
        LibResolverBase.ResolverBaseStorage storage s = LibResolverBase.resolverBaseStorage();
        s.approvedControllers[controller][approved];
        emit ControllerUpdated(controller, approved);
    }

    /// @dev See {IERC1155-setApprovalForAll}.
    function setApprovalForAll(address operator, bool approved) external {
        LibResolverBase.ResolverBaseStorage storage s = LibResolverBase.resolverBaseStorage();
        s.operators[msg.sender][operator] = approved;
    }

    /// @dev See {IERC1155-isApprovedForAll}.
    function isApprovedForAll(address account, address operator) public view returns (bool) {
        LibResolverBase.ResolverBaseStorage storage s = LibResolverBase.resolverBaseStorage();
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
        LibResolverBase.ResolverBaseStorage storage s = LibResolverBase.resolverBaseStorage();
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
        LibResolverBase.ResolverBaseStorage storage s = LibResolverBase.resolverBaseStorage();
        return s.tokenApprovals[owner][node][delegate];
    }


    /**
     * Increments the record version associated with a node.
     * May only be called by the owner of that node in the registry.
     * @param node The node to update.
     */
    function clearRecords(bytes32 node) public LibResolverBase.isAuthroized(node,msg.sender) {
        LibResolverBase.isAuthorized(node, msg.sender);
        LibResolverBase.ResolverBaseStorage storage s = LibResolverBase.resolverBaseStorage();
        s.recordVersions[node]++;
        emit VersionChanged(node, s.recordVersions[node]);
    }
}
