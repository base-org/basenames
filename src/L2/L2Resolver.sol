// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ABIResolver} from "ens-contracts/resolvers/profiles/ABIResolver.sol";
import {AddrResolver} from "ens-contracts/resolvers/profiles/AddrResolver.sol";
import {ContentHashResolver} from "ens-contracts/resolvers/profiles/ContentHashResolver.sol";
import {DNSResolver} from "ens-contracts/resolvers/profiles/DNSResolver.sol";
import {ENS} from "ens-contracts/registry/ENS.sol";
import {ExtendedResolver} from "ens-contracts/resolvers/profiles/ExtendedResolver.sol";
import {IExtendedResolver} from "ens-contracts/resolvers/profiles/IExtendedResolver.sol";
import {InterfaceResolver} from "ens-contracts/resolvers/profiles/InterfaceResolver.sol";
import {Multicallable} from "ens-contracts/resolvers/Multicallable.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {NameResolver} from "ens-contracts/resolvers/profiles/NameResolver.sol";
import {PubkeyResolver} from "ens-contracts/resolvers/profiles/PubkeyResolver.sol";
import {TextResolver} from "ens-contracts/resolvers/profiles/TextResolver.sol";

import {IReverseRegistrar} from "src/L2/interface/IReverseRegistrar.sol";

/// @title L2 Resolver
///
/// @notice The default resolver for the Base Usernames project. This contract implements the functionality of the ENS
///         PublicResolver while also inheriting ExtendedResolver for compatibility with CCIP-read.
///         Public Resolver: https://github.com/ensdomains/ens-contracts/blob/staging/contracts/resolvers/PublicResolver.sol
///         Extended Resolver: https://github.com/ensdomains/ens-contracts/blob/staging/contracts/resolvers/profiles/ExtendedResolver.sol
///
/// @author Coinbase (https://github.com/base-org/usernames)
/// @author ENS (https://github.com/ensdomains/ens-contracts/tree/staging)
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

    /// @notice The ENS registry.
    ENS public immutable ens;

    /// @notice The trusted registrar controller contract.
    address public registrarController;

    /// @notice The reverse registrar contract.
    address public reverseRegistrar;

    /// @notice A mapping of operators per owner address. An operator is authorized to make changes to
    ///         all names owned by the `owner`.
    mapping(address owner => mapping(address operator => bool isApproved)) private _operatorApprovals;

    /// @notice A mapping of delegates per owner per name (stored as a node). A delegate that is authorised
    ///         by an owner for a name may make changes to the name's resolver.
    mapping(address owner => mapping(bytes32 node => mapping(address delegate => bool isApproved))) private
        _tokenApprovals;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          ERRORS                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Thown when msg.sender tries to set itself as an operator.
    error CantSetSelfAsOperator();

    /// @notice Thrown when msg.sender tries to set itself as a delegate for one of its names.
    error CantSetSelfAsDelegate();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          EVENTS                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

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

    /// @notice Emitted when the owner of this contract updates the Registrar Controller addrress.
    ///
    /// @param newRegistrarController The address of the new RegistrarController contract.
    event RegistrarControllerUpdated(address indexed newRegistrarController);

    /// @notice Emitted when the owner of this contract updates the Reverse Registrar address.
    ///
    /// @param newReverseRegistrar The address of the new ReverseRegistrar contract.
    event ReverseRegistrarUpdated(address indexed newReverseRegistrar);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        IMPLEMENTATION                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice L2 Resolver constructor used to establish the necessary contract configuration.
    ///
    /// @param ens_ The Registry contract.
    /// @param registrarController_ The address of the RegistrarController contract.
    /// @param reverseRegistrar_ The address of the ReverseRegistrar contract.
    /// @param owner_  The permissioned address initialized as the `owner` in the `Ownable` context.
    constructor(ENS ens_, address registrarController_, address reverseRegistrar_, address owner_) {
        ens = ens_;
        registrarController = registrarController_;
        reverseRegistrar = reverseRegistrar_;
        _initializeOwner(owner_);
        IReverseRegistrar(reverseRegistrar_).claim(owner_);
    }

    /// @notice Allows the `owner` to set the registrar controller contract address.
    ///
    /// @dev Emits `RegistrarControllerUpdated` after setting the `registrarController` address.
    ///
    /// @param registrarController_ The address of the new RegistrarController contract.
    function setRegistrarController(address registrarController_) external onlyOwner {
        registrarController = registrarController_;
        emit RegistrarControllerUpdated(registrarController_);
    }

    /// @notice Allows the `owner` to set the reverse registrar contract address.
    ///
    /// @dev Emits `ReverseRegistrarUpdated` after setting the `reverseRegistrar` address.
    ///
    /// @param reverseRegistrar_ The address of the new ReverseRegistrar contract.
    function setReverseRegistrar(address reverseRegistrar_) external onlyOwner {
        reverseRegistrar = reverseRegistrar_;
        emit ReverseRegistrarUpdated(reverseRegistrar_);
    }

    /// @dev See {IERC1155-setApprovalForAll}.
    function setApprovalForAll(address operator, bool approved) external {
        if (msg.sender == operator) revert CantSetSelfAsOperator();

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @dev See {IERC1155-isApprovedForAll}.
    function isApprovedForAll(address account, address operator) public view returns (bool) {
        return _operatorApprovals[account][operator];
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
        if (msg.sender == delegate) revert CantSetSelfAsDelegate();

        _tokenApprovals[msg.sender][node][delegate] = approved;
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
        return _tokenApprovals[owner][node][delegate];
    }

    /// @notice Check to see whether `msg.sender` is authorized to modify records for the specified `node`.
    ///
    /// @dev Override for `ResolverBase:isAuthorised()`. Used in the context of each inherited resolver "profile".
    ///     Validates that `msg.sender` is one of:
    ///     1. The stored registrarController (for setting records upon registration)
    ///     2  The stored reverseRegistrar (for setting reverse records)
    ///     3. The owner of the node in the Registry
    ///     4. An approved operator for owner
    ///     5. An approved delegate for owner of the specified `node`
    ///
    /// @param node The namehashed `node` being authorized.
    ///
    /// @return `true` if `msg.sender` is authorized to modify records for the specified `node`, else `false`.
    function isAuthorised(bytes32 node) internal view override returns (bool) {
        if (msg.sender == registrarController || msg.sender == reverseRegistrar) {
            return true;
        }
        address owner = ens.owner(node);
        return owner == msg.sender || isApprovedForAll(owner, msg.sender) || isApprovedFor(owner, node, msg.sender);
    }

    /// @notice ERC165 compliant signal for interface support.
    ///
    /// @dev Checks interface support for each inherited resolver profile
    ///     https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
    ///
    /// @param interfaceID the ERC165 iface id being checked for compliance
    ///
    /// @return bool Whether this contract supports the provided interfaceID
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
        return (interfaceID == type(IExtendedResolver).interfaceId || super.supportsInterface(interfaceID));
    }
}
