//SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ENS} from "ens-contracts/registry/ENS.sol";
import {IReverseRegistrar} from "ens-contracts/reverseRegistrar/IReverseRegistrar.sol";
import {NameResolver} from "ens-contracts/resolvers/profiles/NameResolver.sol";
import {Ownable} from "solady/auth/Ownable.sol";

import {ADDR_REVERSE_NODE} from "src/util/Constants.sol";

contract ReverseRegistrar is Ownable, IReverseRegistrar {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    ENS public immutable ens;
    NameResolver public defaultResolver;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          CONSTANTS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    bytes32 constant SHA3_LOOKUP = 0x3031323334353637383961626364656600000000000000000000000000000000;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          ERRORS                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    error NotAuthorized(address addr, address sender);
    error NoZeroAddress();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          EVENTS                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    event ReverseClaimed(address indexed addr, bytes32 indexed node);
    event DefaultResolverChanged(NameResolver indexed resolver);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          MODIFIERS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    modifier authorized(address addr) {
        if (addr != msg.sender || !ens.isApprovedForAll(addr, msg.sender) || !ownsContract(addr)) {
            revert NotAuthorized(addr, msg.sender);
        }
        _;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        IMPLEMENTATION                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    /**
     * @dev Constructor
     * @param ensAddr The address of the ENS registry.
     * @param _owner The owner of the contract
     */
    constructor(ENS ensAddr, address _owner) {
        _initializeOwner(_owner);
        ens = ensAddr;

        // Assign ownership of the reverse record to our deployer
        ReverseRegistrar oldRegistrar = ReverseRegistrar(ensAddr.owner(ADDR_REVERSE_NODE));
        if (address(oldRegistrar) != address(0x0)) {
            oldRegistrar.claim(msg.sender);
        }
    }

    function setDefaultResolver(address resolver) public override onlyOwner {
        if (address(resolver) == address(0)) revert NoZeroAddress();
        defaultResolver = NameResolver(resolver);
        emit DefaultResolverChanged(NameResolver(resolver));
    }

    /**
     * @dev Transfers ownership of the reverse ENS record associated with the
     *      calling account.
     * @param owner The address to set as the owner of the reverse record in ENS.
     * @return The ENS node hash of the reverse record.
     */
    function claim(address owner) public override returns (bytes32) {
        return claimForAddr(msg.sender, owner, address(defaultResolver));
    }

    /**
     * @dev Transfers ownership of the reverse ENS record associated with the
     *      calling account.
     * @param addr The reverse record to set
     * @param owner The address to set as the owner of the reverse record in ENS.
     * @param resolver The resolver of the reverse node
     * @return The ENS node hash of the reverse record.
     */
    function claimForAddr(address addr, address owner, address resolver)
        public
        override
        authorized(addr)
        returns (bytes32)
    {
        bytes32 labelHash = sha3HexAddress(addr);
        bytes32 reverseNode = keccak256(abi.encodePacked(ADDR_REVERSE_NODE, labelHash));
        emit ReverseClaimed(addr, reverseNode);
        ens.setSubnodeRecord(ADDR_REVERSE_NODE, labelHash, owner, resolver, 0);
        return reverseNode;
    }

    /**
     * @dev Transfers ownership of the reverse ENS record associated with the
     *      calling account.
     * @param owner The address to set as the owner of the reverse record in ENS.
     * @param resolver The address of the resolver to set; 0 to leave unchanged.
     * @return The ENS node hash of the reverse record.
     */
    function claimWithResolver(address owner, address resolver) public override returns (bytes32) {
        return claimForAddr(msg.sender, owner, resolver);
    }

    /**
     * @dev Sets the `name()` record for the reverse ENS record associated with
     * the calling account. First updates the resolver to the default reverse
     * resolver if necessary.
     * @param name The name to set for this address.
     * @return The ENS node hash of the reverse record.
     */
    function setName(string memory name) public override returns (bytes32) {
        return setNameForAddr(msg.sender, msg.sender, address(defaultResolver), name);
    }

    /**
     * @dev Sets the `name()` record for the reverse ENS record associated with
     * the account provided. Updates the resolver to a designated resolver
     * Only callable by controllers and authorised users
     * @param addr The reverse record to set
     * @param owner The owner of the reverse node
     * @param resolver The resolver of the reverse node
     * @param name The name to set for this address.
     * @return The ENS node hash of the reverse record.
     */
    function setNameForAddr(address addr, address owner, address resolver, string memory name)
        public
        override
        returns (bytes32)
    {
        bytes32 node_ = claimForAddr(addr, owner, resolver);
        NameResolver(resolver).setName(node_, name);
        return node_;
    }

    /**
     * @dev Returns the node hash for a given account's reverse records.
     * @param addr The address to hash
     * @return The ENS node hash.
     */
    function node(address addr) public pure override returns (bytes32) {
        return keccak256(abi.encodePacked(ADDR_REVERSE_NODE, sha3HexAddress(addr)));
    }

    function ownsContract(address addr) internal view returns (bool) {
        try Ownable(addr).owner() returns (address owner) {
            return owner == msg.sender;
        } catch {
            return false;
        }
    }

    /**
     * @dev An optimised function to compute the sha3 of the lower-case
     *      hexadecimal representation of an Ethereum address.
     * @param addr The address to hash
     * @return ret The SHA3 hash of the lower-case hexadecimal encoding of the
     *         input address.
     */
    function sha3HexAddress(address addr) private pure returns (bytes32 ret) {
        assembly {
            for { let i := 40 } gt(i, 0) {} {
                i := sub(i, 1)
                mstore8(i, byte(and(addr, 0xf), SHA3_LOOKUP))
                addr := div(addr, 0x10)
                i := sub(i, 1)
                mstore8(i, byte(and(addr, 0xf), SHA3_LOOKUP))
                addr := div(addr, 0x10)
            }

            ret := keccak256(0, 40)
        }
    }
}
