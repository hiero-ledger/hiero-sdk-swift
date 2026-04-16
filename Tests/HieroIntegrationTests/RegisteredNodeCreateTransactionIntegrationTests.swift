// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal final class RegisteredNodeCreateTransactionIntegrationTests: HieroIntegrationTestCase {

    private func makeBlockNodeEndpoint() -> RegisteredServiceEndpoint {
        .blockNode(
            address: .ipAddress(Data([1, 2, 3, 4])),
            port: 8080,
            requiresTls: true,
            endpointApis: [.subscribeStream]
        )
    }

    internal func test_CanCreateRegisteredNodeWithBlockNodeEndpoint() async throws {
        // Given
        let adminKey = PrivateKey.generateEd25519()

        // When
        let receipt = try await RegisteredNodeCreateTransaction()
            .adminKey(.single(adminKey.publicKey))
            .description("Test Block Node")
            .addServiceEndpoint(makeBlockNodeEndpoint())
            .freezeWith(testEnv.adminClient)
            .sign(adminKey)
            .execute(testEnv.adminClient)
            .getReceipt(testEnv.adminClient)

        // Then
        XCTAssertEqual(receipt.status, .success)
        let registeredNodeId = try XCTUnwrap(receipt.registeredNodeId)
        XCTAssertGreaterThan(registeredNodeId, 0)

        // Cleanup
        _ = try await RegisteredNodeDeleteTransaction()
            .registeredNodeId(registeredNodeId)
            .freezeWith(testEnv.adminClient)
            .sign(adminKey)
            .execute(testEnv.adminClient)
            .getReceipt(testEnv.adminClient)
    }

    internal func test_CanCreateRegisteredNodeWithMirrorNodeEndpoint() async throws {
        // Given
        let adminKey = PrivateKey.generateEd25519()

        // When
        let receipt = try await RegisteredNodeCreateTransaction()
            .adminKey(.single(adminKey.publicKey))
            .addServiceEndpoint(
                .mirrorNode(address: .domainName("mirror.example.com"), port: 5551, requiresTls: true)
            )
            .freezeWith(testEnv.adminClient)
            .sign(adminKey)
            .execute(testEnv.adminClient)
            .getReceipt(testEnv.adminClient)

        // Then
        XCTAssertEqual(receipt.status, .success)
        let registeredNodeId = try XCTUnwrap(receipt.registeredNodeId)

        // Cleanup
        _ = try await RegisteredNodeDeleteTransaction()
            .registeredNodeId(registeredNodeId)
            .freezeWith(testEnv.adminClient)
            .sign(adminKey)
            .execute(testEnv.adminClient)
            .getReceipt(testEnv.adminClient)
    }

    internal func test_CanCreateRegisteredNodeWithRpcRelayEndpoint() async throws {
        // Given
        let adminKey = PrivateKey.generateEd25519()

        // When
        let receipt = try await RegisteredNodeCreateTransaction()
            .adminKey(.single(adminKey.publicKey))
            .addServiceEndpoint(
                .rpcRelay(address: .domainName("relay.example.com"), port: 7546, requiresTls: true)
            )
            .freezeWith(testEnv.adminClient)
            .sign(adminKey)
            .execute(testEnv.adminClient)
            .getReceipt(testEnv.adminClient)

        // Then
        XCTAssertEqual(receipt.status, .success)
        let registeredNodeId = try XCTUnwrap(receipt.registeredNodeId)

        // Cleanup
        _ = try await RegisteredNodeDeleteTransaction()
            .registeredNodeId(registeredNodeId)
            .freezeWith(testEnv.adminClient)
            .sign(adminKey)
            .execute(testEnv.adminClient)
            .getReceipt(testEnv.adminClient)
    }

    internal func test_CanCreateRegisteredNodeWithMixedEndpoints() async throws {
        // Given
        let adminKey = PrivateKey.generateEd25519()

        // When
        let receipt = try await RegisteredNodeCreateTransaction()
            .adminKey(.single(adminKey.publicKey))
            .addServiceEndpoint(makeBlockNodeEndpoint())
            .addServiceEndpoint(
                .mirrorNode(address: .domainName("mirror.example.com"), port: 5551, requiresTls: true)
            )
            .addServiceEndpoint(
                .rpcRelay(address: .domainName("relay.example.com"), port: 7546, requiresTls: true)
            )
            .freezeWith(testEnv.adminClient)
            .sign(adminKey)
            .execute(testEnv.adminClient)
            .getReceipt(testEnv.adminClient)

        // Then
        XCTAssertEqual(receipt.status, .success)
        let registeredNodeId = try XCTUnwrap(receipt.registeredNodeId)

        // Cleanup
        _ = try await RegisteredNodeDeleteTransaction()
            .registeredNodeId(registeredNodeId)
            .freezeWith(testEnv.adminClient)
            .sign(adminKey)
            .execute(testEnv.adminClient)
            .getReceipt(testEnv.adminClient)
    }

    internal func test_CanCreateRegisteredNodeWithDescription() async throws {
        // Given
        let adminKey = PrivateKey.generateEd25519()

        // When
        let receipt = try await RegisteredNodeCreateTransaction()
            .adminKey(.single(adminKey.publicKey))
            .description("My Block Node Description")
            .addServiceEndpoint(makeBlockNodeEndpoint())
            .freezeWith(testEnv.adminClient)
            .sign(adminKey)
            .execute(testEnv.adminClient)
            .getReceipt(testEnv.adminClient)

        // Then
        XCTAssertEqual(receipt.status, .success)
        let registeredNodeId = try XCTUnwrap(receipt.registeredNodeId)

        // Cleanup
        _ = try await RegisteredNodeDeleteTransaction()
            .registeredNodeId(registeredNodeId)
            .freezeWith(testEnv.adminClient)
            .sign(adminKey)
            .execute(testEnv.adminClient)
            .getReceipt(testEnv.adminClient)
    }
}
