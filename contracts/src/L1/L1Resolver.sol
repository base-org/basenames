// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

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

    error OffchainLookup(address sender, string[] urls, bytes callData, bytes4 callbackFunction, bytes extraData);

    event NewSigners(address[] signers);
    event NewUrl(string newUrl);
    event NewRootResolver(address resolver);
    event RemovedSigner(address signer);

    constructor(string memory _url, address[] memory _signers, address _owner, address _rootResolver) {
        url = _url;
        _initializeOwner(_owner);
        rootResolver = _rootResolver;

        for (uint256 i = 0; i < _signers.length; i++) {
            signers[_signers[i]] = true;
        }
        emit NewSigners(_signers);
    }

    function setUrl(string calldata _url) external onlyOwner {
        url = _url;
        emit NewUrl(_url);
    }

    function addSigners(address[] calldata _signers) external onlyOwner {
        for (uint256 i; i < _signers.length; i++) {
            signers[_signers[i]] == true;
        }
        emit NewSigners(_signers);
    }

    function removeSigner(address _signer) external onlyOwner {
        if (signers[_signer]) {
            delete signers[_signer];
            emit RemovedSigner(_signer);
        }
    }

    function setRootResolver(address _rootResolver) external onlyOwner {
        rootResolver = _rootResolver;
        emit NewRootResolver(_rootResolver);
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
        // Resolution for root name should fallback to existing resolver
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
        require(signers[signer], "SignatureVerifier: Invalid sigature");
        return result;
    }

    function supportsInterface(bytes4 interfaceID) public view override returns (bool) {
        return interfaceID == type(IExtendedResolver).interfaceId || super.supportsInterface(interfaceID);
    }

    // Handler for arbitrary resolution calls
    fallback() external {
        address RESOLVER = rootResolver;
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the root resolver.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), RESOLVER, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            return(0, returndatasize())
        }
    }
}
