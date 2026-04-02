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

        // Step 1: Generate admin key
        let adminKey = PrivateKey.generateEd25519()
        print("Step 1: Generated admin key: \(adminKey.publicKey)")

        // Step 2: Create a block node endpoint (IP address, SUBSCRIBE_STREAM, TLS)
        let blockEndpoint = RegisteredServiceEndpoint.blockNode(
            address: .ipAddress(Data([1, 2, 3, 4])),
            port: 8080,
            requiresTls: true,
            endpointApi: .subscribeStream
        )
        print("Step 2: Created block node endpoint (1.2.3.4:8080, SUBSCRIBE_STREAM, TLS)")

        // Step 3: Create the registered node
        print("\nStep 3: Executing RegisteredNodeCreateTransaction...")
        let createReceipt = try await RegisteredNodeCreateTransaction()
            .adminKey(.single(adminKey.publicKey))
            .description("My Block Node")
            .addServiceEndpoint(blockEndpoint)
            .freezeWith(client)
            .sign(adminKey)
            .execute(client)
            .getReceipt(client)

        print("  Status: \(createReceipt.status)")

        // Step 4: Verify the registeredNodeId
        guard let registeredNodeId = createReceipt.registeredNodeId, registeredNodeId != 0 else {
            print("ERROR: Expected a non-zero registeredNodeId in the receipt.")
            return
        }
        print("\nStep 4: registeredNodeId = \(registeredNodeId)")

        // Step 5: Create a second endpoint (domain name, STATUS api)
        let statusEndpoint = RegisteredServiceEndpoint.blockNode(
            address: .domainName("block-node.example.com"),
            port: 8443,
            requiresTls: true,
            endpointApi: .status
        )
        print("\nStep 5: Created second endpoint (block-node.example.com:8443, STATUS, TLS)")

        // Step 6: Update the registered node
        print("\nStep 6: Executing RegisteredNodeUpdateTransaction...")
        let updateReceipt = try await RegisteredNodeUpdateTransaction()
            .registeredNodeId(registeredNodeId)
            .description("My Updated Block Node")
            .addServiceEndpoint(blockEndpoint)
            .addServiceEndpoint(statusEndpoint)
            .freezeWith(client)
            .sign(adminKey)
            .execute(client)
            .getReceipt(client)

        print("  Status: \(updateReceipt.status)")

        // Steps 12-14 of the design doc lifecycle: associate the registered node with
        // an existing consensus node via NodeUpdateTransaction. This requires privileged
        // access (the consensus node's admin key) and is intentionally omitted here.
        // let nodeUpdateReceipt = try await NodeUpdateTransaction()
        //     .nodeId(3)
        //     .addAssociatedRegisteredNode(registeredNodeId)
        //     .execute(client)
        //     .getReceipt(client)

        // Step 7: Delete the registered node
        print("\nStep 7: Executing RegisteredNodeDeleteTransaction...")
        let deleteReceipt = try await RegisteredNodeDeleteTransaction()
            .registeredNodeId(registeredNodeId)
            .freezeWith(client)
            .sign(adminKey)
            .execute(client)
            .getReceipt(client)

        print("  Status: \(deleteReceipt.status)")
        print("\n=== Lifecycle complete ===")
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
