// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// @param ETH_NODE The node hash of "eth"
bytes32 constant ETH_NODE = 0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;
// @param BASE_ETH_NODE The node hash of "base.eth"
bytes32 constant BASE_ETH_NODE = 0xff1e3c0eb00ec714e34b6114125fbde1dea2f24a72fbf672e7b7fd5690328e10;
// @param REVERSE_NODE The node hash of "reverse"
bytes32 constant REVERSE_NODE = 0xa097f6721ce401e757d1223a763fef49b8b5f90bb18567ddb86fd205dff71d34;
// @param ADDR_REVERSE_NODE The node hash of "addr.reverse"
bytes32 constant ADDR_REVERSE_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;
// @param BASE_REVERSE_NODE The ENSIP-19 compliant base-specific reverse node hash of "80002105.reverse"
bytes32 constant BASE_REVERSE_NODE = 0x08d9b0993eb8c4da57c37a4b84a6e384c2623114ff4e9370ed51c9b8935109ba;
// @param GRACE_PERIOD the grace period for expired names
uint256 constant GRACE_PERIOD = 90 days;
// @param BASE_ETH_NAME The dnsName of "base.eth" returned by NameEncoder.dnsEncode("base.eth")
bytes constant BASE_ETH_NAME = hex"04626173650365746800";
