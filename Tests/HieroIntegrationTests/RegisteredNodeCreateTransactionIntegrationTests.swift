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

    private func findNode(_ id: UInt64) async throws -> RegisteredNode {
        let book = try await RegisteredNodeAddressBookQuery().execute(testEnv.adminClient)
        return try XCTUnwrap(book.registeredNodes.first { $0.registeredNodeId == id })
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

        let node = try await findNode(registeredNodeId)
        XCTAssertTrue(
            node.serviceEndpoints.contains { if case .blockNode = $0 { return true }; return false },
            "Expected a block node endpoint"
        )

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

        let node = try await findNode(registeredNodeId)
        XCTAssertTrue(
            node.serviceEndpoints.contains { if case .mirrorNode = $0 { return true }; return false },
            "Expected a mirror node endpoint"
        )

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

        let node = try await findNode(registeredNodeId)
        XCTAssertTrue(
            node.serviceEndpoints.contains { if case .rpcRelay = $0 { return true }; return false },
            "Expected an RPC relay endpoint"
        )

        // Cleanup
        _ = try await RegisteredNodeDeleteTransaction()
            .registeredNodeId(registeredNodeId)
            .freezeWith(testEnv.adminClient)
            .sign(adminKey)
            .execute(testEnv.adminClient)
            .getReceipt(testEnv.adminClient)
    }

    internal func test_CanCreateRegisteredNodeWithGeneralServiceEndpoint() async throws {
        // Given
        let adminKey = PrivateKey.generateEd25519()

        // When
        let receipt = try await RegisteredNodeCreateTransaction()
            .adminKey(.single(adminKey.publicKey))
            .addServiceEndpoint(
                .generalService(
                    address: .domainName("custom.example.com"), port: 9000, requiresTls: true,
                    description: "Custom service")
            )
            .freezeWith(testEnv.adminClient)
            .sign(adminKey)
            .execute(testEnv.adminClient)
            .getReceipt(testEnv.adminClient)

        // Then
        XCTAssertEqual(receipt.status, .success)
        let registeredNodeId = try XCTUnwrap(receipt.registeredNodeId)

        let node = try await findNode(registeredNodeId)
        let generalEndpoint = node.serviceEndpoints.compactMap {
            if case .generalService(let ep) = $0 { return ep } else { return nil }
        }.first
        XCTAssertNotNil(generalEndpoint, "Expected a general service endpoint")
        XCTAssertEqual(generalEndpoint?.description, "Custom service")

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
            .addServiceEndpoint(
                .generalService(
                    address: .domainName("custom.example.com"), port: 9000, requiresTls: false,
                    description: "Custom service")
            )
            .freezeWith(testEnv.adminClient)
            .sign(adminKey)
            .execute(testEnv.adminClient)
            .getReceipt(testEnv.adminClient)

        // Then
        XCTAssertEqual(receipt.status, .success)
        let registeredNodeId = try XCTUnwrap(receipt.registeredNodeId)

        let node = try await findNode(registeredNodeId)
        let endpoints = node.serviceEndpoints
        XCTAssertTrue(
            endpoints.contains { if case .blockNode = $0 { return true }; return false },
            "Expected a block node endpoint"
        )
        XCTAssertTrue(
            endpoints.contains { if case .mirrorNode = $0 { return true }; return false },
            "Expected a mirror node endpoint"
        )
        XCTAssertTrue(
            endpoints.contains { if case .rpcRelay = $0 { return true }; return false },
            "Expected an RPC relay endpoint"
        )
        XCTAssertTrue(
            endpoints.contains { if case .generalService = $0 { return true }; return false },
            "Expected a general service endpoint"
        )

        // Cleanup
        _ = try await RegisteredNodeDeleteTransaction()
            .registeredNodeId(registeredNodeId)
            .freezeWith(testEnv.adminClient)
            .sign(adminKey)
            .execute(testEnv.adminClient)
            .getReceipt(testEnv.adminClient)
    }

    internal func test_FailsToCreateRegisteredNodeWithoutAdminKey() async throws {
        // When / Then: no adminKey set — fails precheck because admin key is required
        await assertPrecheckStatus(
            try await RegisteredNodeCreateTransaction()
                .addServiceEndpoint(makeBlockNodeEndpoint())
                .freezeWith(testEnv.adminClient)
                .execute(testEnv.adminClient)
                .getReceipt(testEnv.adminClient),
            .keyRequired
        )
    }

    internal func test_FailsToCreateRegisteredNodeWithEmptyEndpoints() async throws {
        // Given
        let adminKey = PrivateKey.generateEd25519()

        // When / Then: serviceEndpoints list is empty — service endpoints must be non-empty
        await assertReceiptStatus(
            try await RegisteredNodeCreateTransaction()
                .adminKey(.single(adminKey.publicKey))
                .freezeWith(testEnv.adminClient)
                .sign(adminKey)
                .execute(testEnv.adminClient)
                .getReceipt(testEnv.adminClient),
            .invalidRegisteredEndpoint
        )
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

        let node = try await findNode(registeredNodeId)
        XCTAssertEqual(node.description, "My Block Node Description")

        // Cleanup
        _ = try await RegisteredNodeDeleteTransaction()
            .registeredNodeId(registeredNodeId)
            .freezeWith(testEnv.adminClient)
            .sign(adminKey)
            .execute(testEnv.adminClient)
            .getReceipt(testEnv.adminClient)
    }
}
