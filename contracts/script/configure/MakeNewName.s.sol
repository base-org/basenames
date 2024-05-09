// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import {Registry} from "src/L2/Registry.sol";
import {L2Resolver} from "src/L2/L2Resolver.sol";
import "src/util/Constants.sol";
import "ens-contracts/utils/NameEncoder.sol";
import "solady/utils/LibString.sol";

contract MakeNewName is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);


        // NAME AND RECORD DEFS /////////////////////////////
        string memory NAME = "david";
        address NAME_OWNER = deployerAddress;
        address RESOLVED_ADDR = 0xB18e4C959bccc8EF86D78DC297fb5efA99550d85;
        
        ///////////////////////////////////////////////////// 


        address ensAddress = 0xBD69dd64b94fe7435157F4851e4b4Aa3A0988c90;    // deployer-owned registry
        address resolverAddr = 0xd9d7B7C7f89985e9abAfCa5Bc1211BA5d7C49d33;  // l2 resolver 
        Registry registry = Registry(ensAddress);


        // establish the new name as a subnode of the base.eth namespace  
        bytes32 nameLabel = keccak256(bytes(NAME));
        registry.setSubnodeRecord(
            BASE_ETH_NODE, 
            nameLabel, 
            NAME_OWNER,
            resolverAddr,
            type(uint64).max
        );
        (,bytes32 nameNode) = NameEncoder.dnsEncodeName(LibString.concat(NAME, ".base.eth"));
        assert(registry.resolver(nameNode) == resolverAddr);


        // establish records for the new name
        L2Resolver resolver = L2Resolver(resolverAddr);
        resolver.setAddr(nameNode, RESOLVED_ADDR);
        assert(resolver.addr(nameNode) == RESOLVED_ADDR);


        vm.stopBroadcast();
    }
}