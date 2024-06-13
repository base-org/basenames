# BASE USERNAMES

This repository contians code for minting and managing [ENS](https://docs.ens.domains/) subdomains on the Base network. 

It supports:
- Registering base.eth subdomains on Base natively
- Managing the name with a public resolver, allowing an owner or operator to set address records, text records, dns records, etc.
- ERC721 compatible base.eth subdomain tokens 

### OVERVIEW

We think that usernames are an important primitive in bringing the next billion users on-chain. Unique, human-readable identifiers are synonymous with online platforms. On-chain identity solves this same facet of interaction while also inheriting the magic properties of on-chain, cross-platform compatibility. 

To support this effort, this repo implements an identity solution that is native to Base. By leveraging the extensive groundwork established by ENS, we will offer our users usernames that are subdomains of our base.eth L1 ENS namespace.

Luckily, we’re not starting from scratch. The ENS team published [ERC-3668](https://eips.ethereum.org/EIPS/eip-3668) which prescribes a mechanism by which cross-chain name resolution can be accomplished. The Coinbase Wallet team demonstrated this via cb.ids. These names are a half-step towards cross-chain subdomains but still rely on off-chain databases and services to complete the registration and resolution processes. 

This project will take the next half step, bringing the entire username solution on-chain. 

### ARCHITECTURE

The core functionality of Base Usernames should look familiar to anyone that's looked under the hood  at the [ENS contracts](https://github.com/ensdomains/ens-contracts/tree/staging). We implement a slimmed down fork of the ENS contracts here. Specifically, our implementation leverages heavily inspired contracts of:

| Contract | Role | ENS Implementation | Base Usernames Implementation |
| -------- | ---- | ------------------ | ----------------------------- | 
|[Registry](https://docs.ens.domains/registry/ens)  | Stores [Records](https://github.com/base-org/usernames/blob/c29119fd327b61f896440c317f3dd898e9fa570b/contracts/src/L2/Registry.sol#L7-L11) of subdomains in a flat structure |  [ENSRegistry.sol](https://github.com/ensdomains/ens-contracts/blob/staging/contracts/registry/ENSRegistry.sol) | [Registry.sol](https://github.com/base-org/usernames/blob/master/contracts/src/L2/Registry.sol) |
| [BaseRegistrar](https://docs.ens.domains/registry/eth) | Tokenizes names,  manages ownership and stores expiry | [BaseRegistrarImplementation.sol](https://github.com/ensdomains/ens-contracts/blob/staging/contracts/ethregistrar/BaseRegistrarImplementation.sol) | [BaseRegistrar.sol](https://github.com/base-org/usernames/blob/master/contracts/src/L2/BaseRegistrar.sol) | 
| [ReverseRegistrar](https://docs.ens.domains/registry/reverse) | Manages the reverse lookup to allow the setting of "primary" names for an address | [ReverseRegistrar.sol](https://github.com/ensdomains/ens-contracts/blob/staging/contracts/reverseRegistrar/ReverseRegistrar.sol) | [ReverseRegistrar.sol](https://github.com/base-org/usernames/blob/master/contracts/src/L2/ReverseRegistrar.sol) |
| [L1 Resolver](https://docs.ens.domains/resolvers/ccip-read) | Enables cross-chain, wildcard resolution from L1 | [OffchainResolver.sol](https://github.com/ensdomains/offchain-resolver/blob/main/packages/contracts/contracts/OffchainResolver.sol) | [L1Resolver.sol](https://github.com/base-org/usernames/blob/master/contracts/src/L1/L1Resolver.sol) | 
| [L2 Resolver](https://docs.ens.domains/resolvers/public) | A standard public resolver for storing records associated with namespaces | [PublicResolver.sol](https://github.com/ensdomains/ens-contracts/blob/staging/contracts/resolvers/PublicResolver.sol) | [L2Resolver.sol](https://github.com/base-org/usernames/blob/master/contracts/src/L2/L2Resolver.sol) | 
| Registrar Controller | A permissioned contract which manages registration payment | [ETHRegistrarController.sol](https://github.com/ensdomains/ens-contracts/blob/staging/contracts/ethregistrar/ETHRegistrarController.sol) | [RegistrarController.sol](https://github.com/base-org/usernames/blob/master/contracts/src/L2/RegistrarController.sol) |
| Stable Price Oracle | The source of pricing based on name length and duration of registration | [StablePriceOracle.sol](https://github.com/ensdomains/ens-contracts/blob/staging/contracts/ethregistrar/StablePriceOracle.sol) | [StablePriceOracle.sol](https://github.com/base-org/usernames/blob/master/contracts/src/L2/StablePriceOracle.sol) |
| Exponential Premium Oracle | A Dutch auction pricing mechanism for fairly pricing names after expiry | [ExponentialPremiumPricingOracle.sol](https://github.com/ensdomains/ens-contracts/blob/staging/contracts/ethregistrar/ExponentialPremiumPriceOracle.sol) | [ExponentialPremiumPricingOracle.sol](https://github.com/base-org/usernames/blob/master/contracts/src/L2/ExponentialPremiumPriceOracle.sol) | 

In addition to replicating the base behavior of the ENS protocol, we are offering a series of promotional discounts associcated with various Coinbase product integrations. As such, the Base Usernames ETH Registrar Controller allows users to perform discounted registrations while passing along integration-specific `validationData`.

### Functional Diagrams


## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
