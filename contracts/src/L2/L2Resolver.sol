// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ABIResolver} from "ens-contracts/resolvers/profiles/ABIResolver.sol";
import {AddrResolver} from "ens-contracts/resolvers/profiles/AddrResolver.sol";
import {ContentHashResolver} from "ens-contracts/resolvers/profiles/ContentHashResolver.sol";
import {DNSResolver} from "ens-contracts/resolvers/profiles/DNSResolver.sol";
import {ENS} from "ens-contracts/registry/ENS.sol";
import {ExtendedResolver} from "ens-contracts/resolvers/profiles/ExtendedResolver.sol";
import {InterfaceResolver} from "ens-contracts/resolvers/profiles/InterfaceResolver.sol";
import {Multicallable} from "ens-contracts/resolvers/Multicallable.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {NameResolver} from "ens-contracts/resolvers/profiles/NameResolver.sol";
import {PubkeyResolver} from "ens-contracts/resolvers/profiles/PubkeyResolver.sol";
import {TextResolver} from "ens-contracts/resolvers/profiles/TextResolver.sol";

contract L2Resolver is
    Multicallable,
    ABIResolver,
    AddrResolver,
    ContentHashResolver,
    DNSResolver,
    InterfaceResolver,
    NameResolver,
    PubkeyResolver,
    TextResolver,
    ExtendedResolver,
    Ownable
{
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    ENS public immutable ens;
    address public registrarController;
    address public reverseRegistrar;
    /**
     * A mapping of operators. An address that is authorised for an address
     * may make any changes to the name that the owner could, but may not update
     * the set of authorisations.
     * (owner, operator) => approved
     */
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * A mapping of delegates. A delegate that is authorised by an owner
     * for a name may make changes to the name's resolver, but may not update
     * the set of token approvals.
     * (owner, name, delegate) => approved
     */
    mapping(address => mapping(bytes32 => mapping(address => bool))) private _tokenApprovals;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          ERRORS                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    error CantSetSelfAsOperator();
    error CantSetSelfAsDelegate();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          EVENTS                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    // Logged when an operator is added or removed.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    // Logged when a delegate is approved or  an approval is revoked.
    event Approved(address owner, bytes32 indexed node, address indexed delegate, bool indexed approved);
    event RegistrarControllerUpdated(address indexed newRegistrarController);
    event ReverseRegistrarUpdated(address indexed newReverseRegistrar);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        IMPLEMENTATION                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    constructor(ENS ens_, address registrarController_, address reverseRegistrar_, address owner_) {
        ens = ens_;
        registrarController = registrarController_;
        reverseRegistrar = reverseRegistrar_;
        _initializeOwner(owner_);
    }

    function setRegistrarController(address registrarController_) external onlyOwner {
        registrarController = registrarController_;
        emit RegistrarControllerUpdated(registrarController_);
    }

    function setReverseRegistrar(address reverseRegistrar_) external onlyOwner {
        reverseRegistrar = reverseRegistrar_;
        emit ReverseRegistrarUpdated(reverseRegistrar_);
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) external {
        if (msg.sender == operator) revert CantSetSelfAsOperator();

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev Approve a delegate to be able to updated records on a node.
     */
    function approve(bytes32 node, address delegate, bool approved) external {
        if (msg.sender == delegate) revert CantSetSelfAsDelegate();

        _tokenApprovals[msg.sender][node][delegate] = approved;
        emit Approved(msg.sender, node, delegate, approved);
    }

    /**
     * @dev Check to see if the delegate has been approved by the owner for the node.
     */
    function isApprovedFor(address owner, bytes32 node, address delegate) public view returns (bool) {
        return _tokenApprovals[owner][node][delegate];
    }

    function isAuthorised(bytes32 node) internal view override returns (bool) {
        if (msg.sender == registrarController || msg.sender == reverseRegistrar) {
            return true;
        }
        address owner = ens.owner(node);
        return owner == msg.sender || isApprovedForAll(owner, msg.sender) || isApprovedFor(owner, node, msg.sender);
    }

    function supportsInterface(bytes4 interfaceID)
        public
        view
        override(
            Multicallable,
            ABIResolver,
            AddrResolver,
            ContentHashResolver,
            DNSResolver,
            InterfaceResolver,
            NameResolver,
            PubkeyResolver,
            TextResolver
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceID);
    }
}
