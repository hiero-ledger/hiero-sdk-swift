// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal final class RegisteredNodeUpdateTransactionIntegrationTests: HieroIntegrationTestCase {

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

    internal func test_CanUpdateRegisteredNodeDescription() async throws {
        // Given
        let adminKey = PrivateKey.generateEd25519()
        let nodeId = try await createRegisteredNode(adminKey: adminKey)
        defer {
            Task {
                try? await RegisteredNodeDeleteTransaction()
                    .registeredNodeId(nodeId)
                    .freezeWith(self.testEnv.adminClient)
                    .sign(adminKey)
                    .execute(self.testEnv.adminClient)
                    .getReceipt(self.testEnv.adminClient)
            }
        }

        // When / Then
        let receipt = try await RegisteredNodeUpdateTransaction()
            .registeredNodeId(nodeId)
            .description("Updated Description")
            .freezeWith(testEnv.adminClient)
            .sign(adminKey)
            .execute(testEnv.adminClient)
            .getReceipt(testEnv.adminClient)

        XCTAssertEqual(receipt.status, .success)
    }

    internal func test_CanReplaceRegisteredNodeServiceEndpoints() async throws {
        // Given
        let adminKey = PrivateKey.generateEd25519()
        let nodeId = try await createRegisteredNode(adminKey: adminKey)
        defer {
            Task {
                try? await RegisteredNodeDeleteTransaction()
                    .registeredNodeId(nodeId)
                    .freezeWith(self.testEnv.adminClient)
                    .sign(adminKey)
                    .execute(self.testEnv.adminClient)
                    .getReceipt(self.testEnv.adminClient)
            }
        }

        let newEndpoint = RegisteredServiceEndpoint.blockNode(
            address: .domainName("new-block-node.example.com"),
            port: 9090,
            requiresTls: true,
            endpointApis: [.status]
        )

        // When / Then
        let receipt = try await RegisteredNodeUpdateTransaction()
            .registeredNodeId(nodeId)
            .addServiceEndpoint(newEndpoint)
            .freezeWith(testEnv.adminClient)
            .sign(adminKey)
            .execute(testEnv.adminClient)
            .getReceipt(testEnv.adminClient)

        XCTAssertEqual(receipt.status, .success)
    }

    internal func test_CanChangeAdminKeyWhenSignedByBothKeys() async throws {
        // Given
        let oldAdminKey = PrivateKey.generateEd25519()
        let newAdminKey = PrivateKey.generateEd25519()
        let nodeId = try await createRegisteredNode(adminKey: oldAdminKey)
        defer {
            Task {
                try? await RegisteredNodeDeleteTransaction()
                    .registeredNodeId(nodeId)
                    .freezeWith(self.testEnv.adminClient)
                    .sign(newAdminKey)
                    .execute(self.testEnv.adminClient)
                    .getReceipt(self.testEnv.adminClient)
            }
        }

        // When / Then
        let receipt = try await RegisteredNodeUpdateTransaction()
            .registeredNodeId(nodeId)
            .adminKey(.single(newAdminKey.publicKey))
            .freezeWith(testEnv.adminClient)
            .sign(oldAdminKey)
            .sign(newAdminKey)
            .execute(testEnv.adminClient)
            .getReceipt(testEnv.adminClient)

        XCTAssertEqual(receipt.status, .success)
    }

    internal func test_FailsToChangeAdminKeyWhenOnlyOldKeySigns() async throws {
        // Given
        let oldAdminKey = PrivateKey.generateEd25519()
        let newAdminKey = PrivateKey.generateEd25519()
        let nodeId = try await createRegisteredNode(adminKey: oldAdminKey)
        defer {
            Task {
                try? await RegisteredNodeDeleteTransaction()
                    .registeredNodeId(nodeId)
                    .freezeWith(self.testEnv.adminClient)
                    .sign(oldAdminKey)
                    .execute(self.testEnv.adminClient)
                    .getReceipt(self.testEnv.adminClient)
            }
        }

        // When / Then
        await assertThrowsHErrorAsync(
            try await RegisteredNodeUpdateTransaction()
                .registeredNodeId(nodeId)
                .adminKey(.single(newAdminKey.publicKey))
                .freezeWith(testEnv.adminClient)
                .sign(oldAdminKey)  // new key does NOT sign
                .execute(testEnv.adminClient)
                .getReceipt(testEnv.adminClient)
        )
    }

    internal func test_FailsToUpdateNonExistentRegisteredNode() async throws {
        // Given
        let adminKey = PrivateKey.generateEd25519()

        // When / Then
        await assertThrowsHErrorAsync(
            try await RegisteredNodeUpdateTransaction()
                .registeredNodeId(9_999_999)
                .description("No such node")
                .freezeWith(testEnv.adminClient)
                .sign(adminKey)
                .execute(testEnv.adminClient)
                .getReceipt(testEnv.adminClient)
        )
    }
}
