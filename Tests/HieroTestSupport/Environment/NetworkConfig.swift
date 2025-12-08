// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero

/// Configuration for network connectivity in tests
public struct NetworkConfig {
    public let nodes: [String: AccountId]
    public let mirrorNodes: [String]
    public let networkUpdatePeriod: UInt64?

    /// Whether to use Client.forMirrorNetwork (inferred from configuration)
    public var useMirrorNodeAddressBook: Bool {
        // Use mirror network address book if:
        // 1. Mirror nodes are specified, AND
        // 2. No consensus nodes are specified (empty nodes dict)
        return !mirrorNodes.isEmpty && nodes.isEmpty
    }

    public init(
        nodes: [String: AccountId],
        mirrorNodes: [String] = [],
        networkUpdatePeriod: UInt64? = nil
    ) {
        self.nodes = nodes
        self.mirrorNodes = mirrorNodes
        self.networkUpdatePeriod = networkUpdatePeriod
    }

    /// Create network configuration from environment type
    public static func fromEnvironmentType(_ type: TestEnvironmentType) -> Self {
        // Read consensus nodes from environment
        let consensusNodes = EnvironmentVariables.consensusNodes
        let consensusAccountIds = EnvironmentVariables.consensusNodeAccountIds
        let mirrorNodes = EnvironmentVariables.mirrorNodes

        // Build consensus node map if specified
        var nodes: [String: AccountId] = [:]
        if !consensusNodes.isEmpty {
            // Check if counts match
            if consensusNodes.count != consensusAccountIds.count {
                let useCount = min(consensusNodes.count, consensusAccountIds.count)
                print(
                    "WARNING: TEST_CONSENSUS_NODES count (\(consensusNodes.count)) doesn't match TEST_CONSENSUS_NODE_ACCOUNT_IDS count (\(consensusAccountIds.count)). Using first \(useCount) node(s)."
                )
            }

            // Build node map using as many nodes as have account IDs
            for (address, accountIdStr) in zip(consensusNodes, consensusAccountIds) {
                if let accountId = try? AccountId.fromString(accountIdStr) {
                    nodes[address] = accountId
                } else {
                    print("WARNING: Invalid account ID: \(accountIdStr)")
                }
            }
        } else if type == .local {
            // Local defaults from TestDefaults.swift
            if let accountId = try? AccountId.fromString(TestDefaults.localConsensusNodeAccountId) {
                nodes = [TestDefaults.localConsensusNode: accountId]
            } else {
                nodes = [TestDefaults.localConsensusNode: AccountId(num: 3)]
            }
        }

        // Mirror nodes: use env var if specified, otherwise local default for .local type
        let finalMirrorNodes: [String]
        if !mirrorNodes.isEmpty {
            finalMirrorNodes = mirrorNodes
        } else if type == .local {
            finalMirrorNodes = [TestDefaults.localMirrorNode]
        } else {
            finalMirrorNodes = []
        }

        return NetworkConfig(
            nodes: nodes,
            mirrorNodes: finalMirrorNodes,
            networkUpdatePeriod: nil
        )
    }
}
