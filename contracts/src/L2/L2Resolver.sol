// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {PublicResolver} from "ens-contracts/resolvers/PublicResolver.sol";
import {ENS} from "ens-contracts/registry/ENS.sol";
import {INameWrapper} from "ens-contracts/wrapper/INameWrapper.sol";

contract L2Resolver is PublicResolver {
    constructor(ENS _ens, INameWrapper _wrapperAddress, address _trustedETHController, address _trustedReverseRegistrar)
        PublicResolver(_ens, _wrapperAddress, _trustedETHController, _trustedReverseRegistrar)
    {}
}
