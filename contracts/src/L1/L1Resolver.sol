// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IExtendedResolver} from "ens-contracts/resolvers/profiles/IExtendedResolver.sol";
import {ERC165} from "lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import {Ownable} from "solady/auth/Ownable.sol";

import {SignatureVerifier} from "src/lib/SignatureVerifier.sol";
import {BASE_ETH_NAME} from "src/util/Constants.sol";

/**
 * Implements an ENS resolver that directs all queries to a CCIP read gateway.
 * Callers must implement EIP 3668 and ENSIP 10.
 */
contract L1Resolver is IExtendedResolver, ERC165, Ownable {
    string public url;
    mapping(address => bool) public signers;
    address public rootResolver;

    error InvalidSigner();
    error OffchainLookup(address sender, string[] urls, bytes callData, bytes4 callbackFunction, bytes extraData);

    event NewSigners(address[] signers);
    event NewUrl(string newUrl);
    event NewRootResolver(address resolver);
    event RemovedSigner(address signer);

    constructor(string memory url_, address[] memory signers_, address owner_, address rootResolver_) {
        url = url_;
        _initializeOwner(owner_);
        rootResolver = rootResolver_;

        for (uint256 i = 0; i < signers_.length; i++) {
            signers[signers_[i]] = true;
        }
        emit NewSigners(signers_);
    }

    function setUrl(string calldata url_) external onlyOwner {
        url = url_;
        emit NewUrl(url_);
    }

    function addSigners(address[] calldata _signers) external onlyOwner {
        for (uint256 i; i < _signers.length; i++) {
            signers[_signers[i]] = true;
        }
        emit NewSigners(_signers);
    }

    function removeSigner(address signer) external onlyOwner {
        if (signers[signer]) {
            delete signers[signer];
            emit RemovedSigner(signer);
        }
    }

    function setRootResolver(address rootResolver_) external onlyOwner {
        rootResolver = rootResolver_;
        emit NewRootResolver(rootResolver_);
    }

    function makeSignatureHash(address target, uint64 expires, bytes memory request, bytes memory result)
        external
        pure
        returns (bytes32)
    {
        return SignatureVerifier.makeSignatureHash(target, expires, request, result);
    }

    /**
     * Resolves a name, as specified by ENSIP 10.
     * @param name The DNS-encoded name to resolve.
     * @param data The ABI encoded data for the underlying resolution function (Eg, addr(bytes32), text(bytes32,string), etc).
     * @return The return data, ABI encoded identically to the underlying function.
     */
    function resolve(bytes calldata name, bytes calldata data) external view override returns (bytes memory) {
        // Resolution for root name "base.eth" should query the `rootResolver`
        // All other requests will be for "*.base.eth" names and should follow the CCIP flow by reverting with OffchainLookup
        if (keccak256(BASE_ETH_NAME) == keccak256(name)) {
            return IExtendedResolver(rootResolver).resolve(name, data);
        }

        bytes memory callData = abi.encodeWithSelector(L1Resolver.resolve.selector, name, data);
        string[] memory urls = new string[](1);
        urls[0] = url;
        revert OffchainLookup(address(this), urls, callData, L1Resolver.resolveWithProof.selector, callData);
    }

    /**
     * Callback used by CCIP read compatible clients to verify and parse the response.
     */
    function resolveWithProof(bytes calldata response, bytes calldata extraData) external view returns (bytes memory) {
        (address signer, bytes memory result) = SignatureVerifier.verify(extraData, response);
        if (!signers[signer]) revert InvalidSigner();
        return result;
    }

    /// @notice ERC165 compliant signal for interface support
    ///
    /// @dev Checks interface support for this contract OR ERC165 OR rootResolver
    /// https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
    ///
    /// @param interfaceID the ERC165 iface id being checked for compliance
    ///
    /// @return bool Whether this contract supports the provided interfaceID
    function supportsInterface(bytes4 interfaceID) public view override returns (bool) {
        return interfaceID == type(IExtendedResolver).interfaceId || super.supportsInterface(interfaceID)
            || ERC165(rootResolver).supportsInterface(interfaceID);
    }

    // Handler for arbitrary resolver calls
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
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}
