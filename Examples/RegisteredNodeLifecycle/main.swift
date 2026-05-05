// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero
import SwiftDotenv

/// Demonstrates the full lifecycle of a registered node as described in HIP-1137.
///
/// Steps:
/// 1. Generate a new admin key pair.
/// 2. Create a BlockNodeServiceEndpoint (IP, SUBSCRIBE_STREAM, TLS enabled).
/// 3. Execute RegisteredNodeCreateTransaction and capture the registeredNodeId from the receipt.
/// 4. Verify the registeredNodeId is non-zero.
/// 5. Create a second endpoint (domain name, STATUS).
/// 6. Execute RegisteredNodeUpdateTransaction with a new description and both endpoints.
/// 7. Execute RegisteredNodeDeleteTransaction to remove the registered node.
@main
internal enum Program {
    internal static func main() async throws {
        let env = try Dotenv.load()
        let client = try Client.forName(env.networkName)
        client.setOperator(env.operatorAccountId, env.operatorKey)

        print("=== HIP-1137 Registered Node Lifecycle ===\n")

        let adminKey = PrivateKey.generateEd25519()
        print("Step 1: Generated admin key: \(adminKey.publicKey)")

        let blockEndpoint = RegisteredServiceEndpoint.blockNode(
            address: .ipAddress(Data([1, 2, 3, 4])),
            port: 8080,
            requiresTls: true,
            endpointApis: [.subscribeStream]
        )
        print("Step 2: Created block node endpoint (1.2.3.4:8080, SUBSCRIBE_STREAM, TLS)")

        let registeredNodeId = try await createNode(client: client, adminKey: adminKey, endpoint: blockEndpoint)
        print("\nStep 4: registeredNodeId = \(registeredNodeId)")

        let statusEndpoint = RegisteredServiceEndpoint.blockNode(
            address: .domainName("block-node.example.com"),
            port: 8443,
            requiresTls: true,
            endpointApis: [.status]
        )
        print("\nStep 5: Created second endpoint (block-node.example.com:8443, STATUS, TLS)")

        try await updateNode(
            client: client, registeredNodeId: registeredNodeId, adminKey: adminKey,
            endpoints: [blockEndpoint, statusEndpoint])
        try await deleteNode(client: client, registeredNodeId: registeredNodeId, adminKey: adminKey)
        print("\n=== Lifecycle complete ===")
    }

    private static func createNode(
        client: Client, adminKey: PrivateKey, endpoint: RegisteredServiceEndpoint
    ) async throws -> UInt64 {
        print("\nStep 3: Executing RegisteredNodeCreateTransaction...")
        let receipt = try await RegisteredNodeCreateTransaction()
            .adminKey(.single(adminKey.publicKey))
            .description("My Block Node")
            .addServiceEndpoint(endpoint)
            .freezeWith(client)
            .sign(adminKey)
            .execute(client)
            .getReceipt(client)
        print("  Status: \(receipt.status)")
        guard let nodeId = receipt.registeredNodeId, nodeId != 0 else {
            preconditionFailure("Expected a non-zero registeredNodeId in the receipt.")
        }
        return nodeId
    }

    private static func updateNode(
        client: Client, registeredNodeId: UInt64, adminKey: PrivateKey,
        endpoints: [RegisteredServiceEndpoint]
    ) async throws {
        print("\nStep 6: Executing RegisteredNodeUpdateTransaction...")
        var tx = RegisteredNodeUpdateTransaction()
            .registeredNodeId(registeredNodeId)
            .description("My Updated Block Node")
        for endpoint in endpoints { tx = tx.addServiceEndpoint(endpoint) }
        let receipt = try await tx.freezeWith(client).sign(adminKey).execute(client).getReceipt(client)
        print("  Status: \(receipt.status)")
    }

    private static func deleteNode(client: Client, registeredNodeId: UInt64, adminKey: PrivateKey) async throws {
        // Steps 12-14 of the design doc lifecycle: associate the registered node with
        // an existing consensus node via NodeUpdateTransaction. This requires privileged
        // access (the consensus node's admin key) and is intentionally omitted here.
        print("\nStep 7: Executing RegisteredNodeDeleteTransaction...")
        let receipt = try await RegisteredNodeDeleteTransaction()
            .registeredNodeId(registeredNodeId)
            .freezeWith(client)
            .sign(adminKey)
            .execute(client)
            .getReceipt(client)
        print("  Status: \(receipt.status)")
    }
}

extension Environment {
    internal var operatorAccountId: AccountId {
        AccountId(self["OPERATOR_ID"]!.stringValue)!
    }

    internal var operatorKey: PrivateKey {
        PrivateKey(self["OPERATOR_KEY"]!.stringValue)!
    }

    internal var networkName: String {
        self["HEDERA_NETWORK"]?.stringValue ?? "testnet"
    }
}
