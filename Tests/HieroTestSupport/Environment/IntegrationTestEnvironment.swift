// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero
import XCTest

/// Integration test environment with client and configuration
public struct IntegrationTestEnvironment {
    public let client: Client
    public let `operator`: (accountId: AccountId, privateKey: PrivateKey)

    private init(client: Client, operator: (accountId: AccountId, privateKey: PrivateKey)) {
        self.client = client
        self.operator = `operator`
    }

    public static func create() async throws -> Self {
        let config = try TestEnvironmentConfig.shared

        guard let operatorConfig = config.operator else {
            throw TestEnvironmentError.missingOperatorCredentials
        }

        let client: Client

        // Check if we should use mirror node address book
        if config.network.useMirrorNodeAddressBook {
            client = try await Client.forMirrorNetwork(config.network.mirrorNodes)
        } else {
            // Use standard network configuration
            switch config.type {
            case .unit:
                throw TestEnvironmentError.invalidConfiguration("Unit tests should not use IntegrationTestEnvironment")

            case .mainnet:
                client = Client.forMainnet()

            case .testnet, .custom:
                client = Client.forTestnet()

            case .previewnet:
                client = Client.forPreviewnet()

            case .local:
                guard !config.network.nodes.isEmpty else {
                    throw TestEnvironmentError.invalidConfiguration("Local network requires node configuration")
                }
                client = try Client.forNetwork(config.network.nodes)
                if !config.network.mirrorNodes.isEmpty {
                    _ = client.setMirrorNetwork(config.network.mirrorNodes)
                }

                if let updatePeriod = config.network.networkUpdatePeriod {
                    await client.setNetworkUpdatePeriod(nanoseconds: updatePeriod)
                } else {
                    await client.setNetworkUpdatePeriod(nanoseconds: nil as UInt64?)
                }
            }
        }

        // Set operator
        client.setOperator(operatorConfig.accountId, operatorConfig.privateKey)

        return IntegrationTestEnvironment(
            client: client,
            operator: (operatorConfig.accountId, operatorConfig.privateKey)
        )
    }
}
