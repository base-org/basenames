//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";

import {AttestationValidator} from "src/L2/discounts/AttestationValidator.sol";
import {BaseRegistrar} from "src/L2/BaseRegistrar.sol";
import {CBIdDiscountValidator} from "src/L2/discounts/CBIdDiscountValidator.sol";
import {ExponentialPremiumPriceOracle} from "src/L2/ExponentialPremiumPriceOracle.sol";
import {ERC1155DiscountValidator} from "src/L2/discounts/ERC1155DiscountValidator.sol";
import {IBaseRegistrar} from "src/L2/interface/IBaseRegistrar.sol";
import {IDiscountValidator} from "src/L2/interface/IDiscountValidator.sol";
import {IPriceOracle} from "src/L2/interface/IPriceOracle.sol";
import {IReverseRegistrar} from "src/L2/interface/IReverseRegistrar.sol";
import {L1Resolver} from "src/L1/L1Resolver.sol";
import {L2Resolver} from "src/L2/L2Resolver.sol";
import {RegistrarController} from "src/L2/RegistrarController.sol";
import {Registry} from "src/L2/Registry.sol";
import {ReverseRegistrar} from "src/L2/ReverseRegistrar.sol";

import {
    ETH_NODE,
    BASE_ETH_NODE,
    REVERSE_NODE,
    ADDR_REVERSE_NODE,
    GRACE_PERIOD,
    BASE_ETH_NAME
} from "src/util/Constants.sol";

contract IntegrationTest is Test {
    address owner;
    address signer;
    address alice;

    L1Resolver l1Resolver;

    Registry registry;
    BaseRegistrar baseRegistrar;
    RegistrarController registrarController;
    L2Resolver defaultL2Resolver;
    ReverseRegistrar reverseRegistrar;
    ExponentialPremiumPriceOracle exponentialPremiumPriceOracle;

    AttestationValidator attestationValidator;
    CBIdDiscountValidator cBIdDiscountValidator;
    ERC1155DiscountValidator eRC1155DiscountValidator;

    bytes32 constant ROOT_NODE = bytes32(0);
    bytes32 constant ETH_LABEL = 0x4f5b812789fc606be1b3b16908db13fc7a9adf7ca72641f84d75b47069d3d7f0;
    bytes32 constant BASE_LABEL = 0xf1f3eb40f5bc1ad1344716ced8b8a0431d840b5783aea1fd01786bc26f35ac0f;
    bytes32 constant REVERSE_LABEL = 0xdec08c9dbbdd0890e300eb5062089b2d4b1c40e3673bbccb5423f7b37dcf9a9c;
    bytes32 constant ADDR_LABEL = 0xe5e14487b78f85faa6e1808e89246cf57dd34831548ff2e6097380d98db2504a;


    function setUp() public {
        owner = makeAddr("owner");
        signer = makeAddr("signer");
        alice = makeAddr("alice");

        registry = new Registry(owner);
        reverseRegistrar = new ReverseRegistrar(registry, owner);        

        uint256[] memory rentPrices = new uint256[](6);
        rentPrices[0] = 317_097_919_837;
        rentPrices[1] = 31_709_791_983;
        rentPrices[2] = 3_170_979_198;
        rentPrices[3] = 317_097_919;
        rentPrices[4] = 31_709_791;
        rentPrices[5] = 3_170_979; //3,170,979.1983764587 = 1e14 / (365 * 24 * 3600)

        exponentialPremiumPriceOracle = new ExponentialPremiumPriceOracle(rentPrices, 1e18, 21);
        baseRegistrar = new BaseRegistrar(registry, owner, BASE_ETH_NODE);

        _establishNamespaces();
        
        registrarController = new RegistrarController(
            baseRegistrar,
            exponentialPremiumPriceOracle,
            IReverseRegistrar(address(reverseRegistrar)),
            owner,
            BASE_ETH_NODE,
            "base.eth"
        );

        vm.prank(owner);
        baseRegistrar.addController(address(registrarController));

        defaultL2Resolver = new L2Resolver(
            registry,
            address(registrarController),
            address(reverseRegistrar),
            owner
        );

        vm.prank(owner);
        reverseRegistrar.setDefaultResolver(address(defaultL2Resolver));

        vm.prank(owner);
        reverseRegistrar.setName("rootOwner");

        vm.warp(GRACE_PERIOD * 10);
    }

    function _establishNamespaces() internal {
        //  establish base.eth namespace and assign ownership of base.eth to the registrar controller 
        vm.startPrank(owner);
        registry.setSubnodeOwner(ROOT_NODE, ETH_LABEL, owner);
        registry.setSubnodeOwner(ETH_NODE, BASE_LABEL, address(baseRegistrar));

        // establish addr.reverse namespace and assign ownership of addr.reverse to the reverse registrar 
        registry.setSubnodeOwner(ROOT_NODE, REVERSE_LABEL, owner);
        registry.setSubnodeOwner(REVERSE_NODE, ADDR_LABEL, address(reverseRegistrar));
        vm.stopPrank();
    }

    function test_integration_register() public {
        vm.stopPrank();
        vm.startPrank(alice);
        

        string memory name = "alice";
        uint256 duration = 90 days;

        uint256 registerPrice = registrarController.registerPrice(name, duration);
        vm.deal(alice, registerPrice);
        
        RegistrarController.RegisterRequest memory request = RegistrarController.RegisterRequest({
            name: name,
            owner: alice,
            duration: duration,
            resolver: address(defaultL2Resolver),
            data: new bytes[](0),
            reverseRecord: true
        });

        registrarController.register{value: registerPrice}(request);
    }
}