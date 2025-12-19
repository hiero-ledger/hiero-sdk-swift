// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero
import XCTest

/// Integration test environment with client and configuration
public struct IntegrationTestEnvironment {

    public let client: Client
    public let adminClient: Client
    public let `operator`: (accountId: AccountId, privateKey: PrivateKey)

    private init(client: Client, adminClient: Client, operator: (accountId: AccountId, privateKey: PrivateKey)) {
        self.client = client
        self.adminClient = adminClient
        self.operator = `operator`
    }

    public static func create() async throws -> Self {
        let config = try TestEnvironmentConfig.shared

        guard let operatorConfig = config.operator else {
            throw TestEnvironmentError.missingOperatorCredentials
        }

        let client: Client
        let adminClient: Client

        // Check if we should use mirror node address book
        if config.network.useMirrorNodeAddressBook {
            client = try await Client.forMirrorNetwork(config.network.mirrorNodes)
            adminClient = try await Client.forMirrorNetwork(config.network.mirrorNodes)
        } else {
            // Use standard network configuration
            switch config.type {
            case .unit:
                throw TestEnvironmentError.invalidConfiguration("Unit tests should not use IntegrationTestEnvironment")

            case .mainnet:
                client = Client.forMainnet()
                adminClient = Client.forMainnet()

            case .testnet:
                client = Client.forTestnet()
                adminClient = Client.forTestnet()

            case .previewnet:
                client = Client.forPreviewnet()
                adminClient = Client.forPreviewnet()

            case .local, .custom:
                // For local and custom environments, use the configured nodes
                guard !config.network.nodes.isEmpty else {
                    throw TestEnvironmentError.invalidConfiguration(
                        "\(config.type) network requires node configuration")
                }
                client = try Client.forNetwork(config.network.nodes)
                adminClient = try Client.forNetwork(config.network.nodes)
                if !config.network.mirrorNodes.isEmpty {
                    _ = client.setMirrorNetwork(config.network.mirrorNodes)
                    _ = adminClient.setMirrorNetwork(config.network.mirrorNodes)
                }
            }
        }

        // Set operator
        client.setOperator(operatorConfig.accountId, operatorConfig.privateKey)
        adminClient.setOperator(
            AccountId(num: 2),
            try PrivateKey.fromString(
                "302e020100300506032b65700422042091132178e72057a1d7528025956fe39b0b847f200ab59b2fdd367017f3087137"))

        // Turn off network updates
        await client.setNetworkUpdatePeriod(nanoseconds: nil as UInt64?)
        await adminClient.setNetworkUpdatePeriod(nanoseconds: nil as UInt64?)

        return IntegrationTestEnvironment(
            client: client,
            adminClient: adminClient,
            operator: (operatorConfig.accountId, operatorConfig.privateKey)
        )
    }
}
