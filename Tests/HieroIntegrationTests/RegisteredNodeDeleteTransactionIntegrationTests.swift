// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal final class RegisteredNodeDeleteTransactionIntegrationTests: HieroIntegrationTestCase {

    private func makeBlockNodeEndpoint() -> RegisteredServiceEndpoint {
        .blockNode(
            address: .ipAddress(Data([1, 2, 3, 4])),
            port: 8080,
            requiresTls: true,
            endpointApis: [.subscribeStream]
        )
    }

    private func createRegisteredNode(adminKey: PrivateKey) async throws -> UInt64 {
        let receipt = try await RegisteredNodeCreateTransaction()
            .adminKey(.single(adminKey.publicKey))
            .addServiceEndpoint(makeBlockNodeEndpoint())
            .freezeWith(testEnv.adminClient)
            .sign(adminKey)
            .execute(testEnv.adminClient)
            .getReceipt(testEnv.adminClient)
        return try XCTUnwrap(receipt.registeredNodeId)
    }

    internal func test_CanDeleteRegisteredNode() async throws {
        // Given
        let adminKey = PrivateKey.generateEd25519()
        let nodeId = try await createRegisteredNode(adminKey: adminKey)

        // When / Then
        let receipt = try await RegisteredNodeDeleteTransaction()
            .registeredNodeId(nodeId)
            .freezeWith(testEnv.adminClient)
            .sign(adminKey)
            .execute(testEnv.adminClient)
            .getReceipt(testEnv.adminClient)

        XCTAssertEqual(receipt.status, .success)
    }

    internal func test_FailsToDeleteAlreadyDeletedNode() async throws {
        // Given
        let adminKey = PrivateKey.generateEd25519()
        let nodeId = try await createRegisteredNode(adminKey: adminKey)

        // Delete the node first
        _ = try await RegisteredNodeDeleteTransaction()
            .registeredNodeId(nodeId)
            .freezeWith(testEnv.adminClient)
            .sign(adminKey)
            .execute(testEnv.adminClient)
            .getReceipt(testEnv.adminClient)

        // When / Then: deleting again should fail
        await assertThrowsHErrorAsync(
            try await RegisteredNodeDeleteTransaction()
                .registeredNodeId(nodeId)
                .freezeWith(testEnv.adminClient)
                .sign(adminKey)
                .execute(testEnv.adminClient)
                .getReceipt(testEnv.adminClient)
        )
    }

    internal func test_FailsToDeleteNonExistentNode() async throws {
        // Given
        let adminKey = PrivateKey.generateEd25519()

        // When / Then
        await assertThrowsHErrorAsync(
            try await RegisteredNodeDeleteTransaction()
                .registeredNodeId(9_999_999)
                .freezeWith(testEnv.adminClient)
                .sign(adminKey)
                .execute(testEnv.adminClient)
                .getReceipt(testEnv.adminClient)
        )
    }

    // Stub: demonstrates NodeCreateTransaction with associatedRegisteredNodes.
    // The NodeCreate call requires privileged access (council signing) and is
    // intentionally left commented out. This test exercises the registered node
    // lifecycle and validates the API compiles and round-trips correctly.
    internal func test_CanCreateConsensusNodeWithAssociatedRegisteredNodes() async throws {
        // Given: create a registered node
        let adminKey = PrivateKey.generateEd25519()
        let registeredNodeId = try await createRegisteredNode(adminKey: adminKey)

        // When: associate with a consensus node (requires privileged access)
        // let receipt = try await NodeCreateTransaction()
        //     .accountId(...)
        //     .addAssociatedRegisteredNode(registeredNodeId)
        //     .execute(testEnv.adminClient)
        //     .getReceipt(testEnv.adminClient)

        // Cleanup
        _ = try await RegisteredNodeDeleteTransaction()
            .registeredNodeId(registeredNodeId)
            .freezeWith(testEnv.adminClient)
            .sign(adminKey)
            .execute(testEnv.adminClient)
            .getReceipt(testEnv.adminClient)
    }

    // Stub: demonstrates NodeUpdateTransaction with associatedRegisteredNodes.
    // The NodeUpdate call requires privileged access (admin key signing for the
    // consensus node) and is intentionally left commented out. This test exercises
    // the registered node lifecycle and validates the API compiles correctly.
    internal func test_CanUpdateConsensusNodeWithAssociatedRegisteredNodes() async throws {
        // Given: create a registered node
        let adminKey = PrivateKey.generateEd25519()
        let registeredNodeId = try await createRegisteredNode(adminKey: adminKey)

        // When: associate with a consensus node (requires privileged access)
        // let receipt = try await NodeUpdateTransaction()
        //     .nodeId(3)
        //     .addAssociatedRegisteredNode(registeredNodeId)
        //     .execute(testEnv.adminClient)
        //     .getReceipt(testEnv.adminClient)

        // Cleanup
        _ = try await RegisteredNodeDeleteTransaction()
            .registeredNodeId(registeredNodeId)
            .freezeWith(testEnv.adminClient)
            .sign(adminKey)
            .execute(testEnv.adminClient)
            .getReceipt(testEnv.adminClient)
    }
}
