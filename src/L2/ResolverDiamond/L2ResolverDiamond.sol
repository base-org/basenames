// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "./lib/LibDiamond.sol";
import {DiamondCutFacet} from "./facets/DiamondCutFacet.sol";

contract L2ResolverDiamond {
    constructor(
        address _contractOwner,
        address _diamondCutFacet,
        LibDiamond.FacetCut[] memory facets,
        address initializer,
        bytes memory data
    ) {
        LibDiamond.setContractOwner(_contractOwner);
        LibDiamond.FacetCut[] memory cuts = new LibDiamond.FacetCut[](facets.length + 1);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = DiamondCutFacet.diamondCut.selector;
        cuts[0] = LibDiamond.FacetCut({
            facetAddress: _diamondCutFacet,
            action: LibDiamond.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        for(uint256 i; i < facets.length; i++) {
            cuts[i+1] = facets[i];
        }
        LibDiamond.diamondCut(cuts, initializer, data);
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}
}
