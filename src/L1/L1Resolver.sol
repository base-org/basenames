// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IExtendedResolver} from "ens-contracts/resolvers/profiles/IExtendedResolver.sol";
import {ERC165} from "lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import {Ownable} from "solady/auth/Ownable.sol";

import {BASE_ETH_NAME} from "src/util/Constants.sol";
import {SignatureVerifier} from "src/lib/SignatureVerifier.sol";

/// @title L1 Resolver
///
/// @notice Resolver for the `base.eth` domain on Ethereum mainnet.
///         It serves two primary functions:
///             1. Resolve base.eth using existing records stored on the `rootResolver` via the `fallback` passthrough
///             2. Initiate and verify wildcard resolution requests, compliant with CCIP-Read aka. ERC-3668
///                 https://eips.ethereum.org/EIPS/eip-3668
///
///         Inspired by ENS's `OffchainResolver`:
///         https://github.com/ensdomains/offchain-resolver/blob/main/packages/contracts/contracts/OffchainResolver.sol
///
/// @author Coinbase (https://github.com/base-org/usernames)
contract L1Resolver is IExtendedResolver, ERC165, Ownable {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice The url endpoint for the CCIP gateway service.
    string public url;

    /// @notice Storage of approved signers.
    mapping(address signer => bool isApproved) public signers;

    /// @notice address of the rootResolver for `base.eth`.
    address public rootResolver;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          ERRORS                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Thrown when an invalid signer is returned from ECDSA recovery.
    error InvalidSigner();

    /// @notice Thrown when initiaitng a CCIP-read, per ERC-3668
    error OffchainLookup(address sender, string[] urls, bytes callData, bytes4 callbackFunction, bytes extraData);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          EVENTS                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Emitted when new signers were added to the approved `signers` mapping.
    event AddedSigners(address[] signers);

    /// @notice Emitted when a new gateway url was stored for `url`.
    ///
    /// @param newUrl the new url being stored.
    event UrlChanged(string newUrl);

    /// @notice Emitted when a new root resolver is set as the `rootResolver`.
    ///
    /// @param resolver The address of the new root resolver.
    event RootResolverChanged(address resolver);

    /// @notice Emitted when a signer has been removed from the approved `signers` mapping.
    ///
    /// @param signer The signer that was removed from the mapping.
    event RemovedSigner(address signer);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        IMPLEMENTATION                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Resolver constructor
    ///
    /// @dev Emits `AddedSigners(signers_)` after setting the mapping for each signer in the `signers_` arg.
    ///
    /// @param url_  The gateway url stored as `url`.
    /// @param signers_  The approved signers array, each stored as approved in the `signers` mapping.
    /// @param owner_  The permissioned address initialized as the `owner` in the `Ownable` context.
    /// @param rootResolver_ The address stored as the `rootResolver`.
    constructor(string memory url_, address[] memory signers_, address owner_, address rootResolver_) {
        url = url_;
        _initializeOwner(owner_);
        rootResolver = rootResolver_;

        for (uint256 i = 0; i < signers_.length; i++) {
            signers[signers_[i]] = true;
        }
        emit AddedSigners(signers_);
    }

    /// @notice Permissioned method letting the owner set the gateway url.
    ///
    /// @dev Emits `UrlChanged(url_)` after storing the new url as `url`.
    ///
    /// @param url_ The gateway url stored as `url`.
    function setUrl(string calldata url_) external onlyOwner {
        url = url_;
        emit UrlChanged(url_);
    }

    /// @notice Permissioned method letting the owner add approved signers.
    ///
    /// @dev Emits `NewSigners(signers_)` after setting the mapping for each signer in the `signers_` arg.
    ///
    /// @param signers_ Array of signers to set as approved signers in the `signers` mapping.
    function addSigners(address[] calldata signers_) external onlyOwner {
        for (uint256 i; i < signers_.length; i++) {
            signers[signers_[i]] = true;
        }
        emit AddedSigners(signers_);
    }

    /// @notice Permissioned method letting the owner remove a signer from the approved `signers` mapping.
    ///
    /// @dev Emits `RemovedSigner(signer)` after setting the signer to false in the `signers` mapping.
    ///
    /// @param signer The signer to remove from the `signers` mapping.
    function removeSigner(address signer) external onlyOwner {
        if (signers[signer]) {
            delete signers[signer];
            emit RemovedSigner(signer);
        }
    }

    /// @notice Permissioned method letting the owner set the address of the root resolver.
    ///
    /// @dev Emits `RootResolverChanged(rootResolver_)` after setting the `rootResolver` address.
    ///
    /// @param rootResolver_ Address of the new `rootResolver`
    function setRootResolver(address rootResolver_) external onlyOwner {
        rootResolver = rootResolver_;
        emit RootResolverChanged(rootResolver_);
    }

    /// @notice Hook into the SignatureVerifier lib `makeSignatureHash` method
    ///
    /// @param target Address of the verifier target.
    /// @param expires Expiry of the signature.
    /// @param request Arbitrary bytes for the initiated request.
    /// @param result Arbitrary bytes for the response to the request.
    ///
    /// @return The resulting signature hash.
    function makeSignatureHash(address target, uint64 expires, bytes memory request, bytes memory result)
        external
        pure
        returns (bytes32)
    {
        return SignatureVerifier.makeSignatureHash(target, expires, request, result);
    }

    /// @notice Resolves a name, as specified by ENSIP-10.
    ///
    /// @dev If the resolution request targets the `BASE_ETH_NAME` == base.eth, this method calls `rootResolver.resolve()`
    ///     Otherwise, the resolution target is implicitly a wildcard resolution request, i.e jesse.base.eth. In this case,
    ///     we revert with `OffchainLookup` according to ENSIP-10.
    ///     ENSIP-10 describes the ENS-specific mechanism to enable CCIP Reads for offchain resolution.
    ///     See: https://docs.ens.domains/ensip/10
    ///
    /// @param name The DNS-encoded name to resolve.
    /// @param data The ABI encoded data for the underlying resolution function (Eg, addr(bytes32), text(bytes32,string), etc).
    ///
    /// @return The return data, ABI encoded identically to the underlying function.
    function resolve(bytes calldata name, bytes calldata data) external view override returns (bytes memory) {
        // Check for base.eth resolution, and resolve return early if so
        if (keccak256(BASE_ETH_NAME) == keccak256(name)) {
            return _resolve(name, data);
        }

        bytes memory callData = abi.encodeWithSelector(IExtendedResolver.resolve.selector, name, data);
        string[] memory urls = new string[](1);
        urls[0] = url;
        revert OffchainLookup(address(this), urls, callData, L1Resolver.resolveWithProof.selector, callData);
    }

    /// @notice Callback used by CCIP read compatible clients to verify and parse the response.
    ///
    /// @dev The response data must be encoded per the following format:
    ///         response = abi.encode(bytes memory result, uint64 expires, bytes memory sig), where:
    ///         `result` is the resolver response to the resolution request.
    ///         `expires` is the signature expiry.
    ///         `sig` is the signature data used for validating that the gateway signed the response.
    ///     Per ENSIP-10, the `extraData` arg must match exectly the `extraData` field from the `OffchainLookup` which initiated
    ///     the CCIP read.
    ///     Reverts with `InvalidSigner` if the recovered address is not in the `singers` mapping.
    ///
    /// @param response The response bytes that the client received from the gateway.
    /// @param extraData The additional bytes of information from the `OffchainLookup` `extraData` arg.
    ///
    /// @return The bytes of the reponse from the CCIP read.
    function resolveWithProof(bytes calldata response, bytes calldata extraData) external view returns (bytes memory) {
        (address signer, bytes memory result) = SignatureVerifier.verify(extraData, response);
        if (!signers[signer]) revert InvalidSigner();
        return result;
    }

    /// @notice ERC165 compliant signal for interface support.
    ///
    /// @dev Checks interface support for this contract OR ERC165 OR rootResolver
    ///     https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
    ///
    /// @param interfaceID the ERC165 iface id being checked for compliance
    ///
    /// @return bool Whether this contract supports the provided interfaceID
    function supportsInterface(bytes4 interfaceID) public view override returns (bool) {
        return interfaceID == type(IExtendedResolver).interfaceId || super.supportsInterface(interfaceID)
            || ERC165(rootResolver).supportsInterface(interfaceID);
    }

    /// @notice Internal method for completing `resolve` intended for the `rootResolver`.
    ///
    /// @dev The `PublicResolver` located at `rootResolver` does not implement the `resolve(bytes,bytes)` method.
    ///     This method completes the resolution request by staticcalling `rootResolver` with the resolve request.
    ///     Implementation matches the ENS `ExtendedResolver:resolve(bytes,bytes)` method with the exception that it `staticcall`s the
    ///     the `rootResolver` instead of `address(this)`.
    ///
    /// @param data The ABI encoded data for the underlying resolution function (Eg, addr(bytes32), text(bytes32,string), etc).
    ///
    /// @return The return data, ABI encoded identically to the underlying function.
    function _resolve(bytes memory, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory result) = rootResolver.staticcall(data);
        if (success) {
            return result;
        } else {
            // Revert with the reason provided by the call
            assembly {
                revert(add(result, 0x20), mload(result))
            }
        }
    }

    /// @notice Generic handler for requests to the `rootResolver`
    ///
    /// @dev Inspired by the passthrough logic of proxy contracts, but leveraging `call` instead of `delegatecall`
    ///     See: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/dc625992575ecb3089acc35f5475bedfcb7e6be3/contracts/proxy/Proxy.sol#L22-L45
    fallback() external {
        address RESOLVER = rootResolver;
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the root resolver.
            // out and outsize are 0 because we don't know the size yet.
            let result := call(gas(), RESOLVER, 0, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // call returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}
