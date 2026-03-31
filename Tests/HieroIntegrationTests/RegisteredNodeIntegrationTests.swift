// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

// swiftlint:disable:next type_body_length
internal final class RegisteredNodeIntegrationTests: HieroIntegrationTestCase {

    // A valid DER-encoded gossip CA certificate for use in consensus node tests (tests 16–17).
    private static let validGossipCertDerHex =
        "3082052830820310a003020102020101300d06092a864886f70d01010c05003010310e300c060355040313056e6f6465333024170d3234313030383134333233395a181332313234313030383134333233392e3337395a3010310e300c060355040313056e6f64653330820222300d06092a864886f70d01010105000382020f003082020a0282020100af111cff0c4ad8125d2f4b8691ce87332fecc867f7a94ddc0f3f96514cc4224d44af516394f7384c1ef0a515d29aa6116b65bc7e4d7e2d848cf79fbfffedae3a6583b3957a438bdd780c4981b800676ea509bc8c619ae04093b5fc642c4484152f0e8bcaabf19eae025b630028d183a2f47caf6d9f1075efb30a4248679d871beef1b7e9115382270cbdb68682fae4b1fd592cadb414d918c0a8c23795c7c5a91e22b3e90c410825a2bc1a840efc5bf9976a7f474c7ed7dc047e4ddd2db631b68bb4475f173baa3edc234c4bed79c83e2f826f79e07d0aade2d984da447a8514135bfa4145274a7f62959a23c4f0fae5adc6855974e7c04164951d052beb5d45cb1f3cdfd005da894dea9151cb62ba43f4731c6bb0c83e10fd842763ba6844ef499f71bc67fa13e4917fb39f2ad18112170d31cdcb3c61c9e3253accf703dbd8427fdcb87ece78b787b6cfdc091e8fedea8ad95dc64074e1fc6d0e42ea2337e18a5e54e4aaab3791a98dfcef282e2ae1caec9cf986fabe8f36e6a21c8711647177e492d264415e765a86c58599cd97b103cb4f6a01d2edd06e3b60470cf64daca7aecf831197b466cae04baeeac19840a05394bef628aed04b611cfa13677724b08ddfd662b02fd0ef0af17eb7f4fb8c1c17fbe9324f6dc7bcc02449622636cc45ec04909b3120ab4df4726b21bf79e955fe8f832699d2196dcd7a58bfeafb170203010001a38186308183300f0603551d130101ff04053003020100300e0603551d0f0101ff0404030204b030200603551d250101ff0416301406082b0601050507030106082b06010505070302301d0603551d0e04160414643118e05209035edd83d44a0c368de2fb2fe4c0301f0603551d23041830168014643118e05209035edd83d44a0c368de2fb2fe4c0300d06092a864886f70d01010c05000382020100ad41c32bb52650eb4b76fce439c9404e84e4538a94916b3dc7983e8b5c58890556e7384601ca7440dde68233bb07b97bf879b64487b447df510897d2a0a4e789c409a9b237a6ad240ad5464f2ce80c58ddc4d07a29a74eb25e1223db6c00e334d7a27d32bfa6183a82f5e35bccf497c2445a526eabb0c068aba9b94cc092ea4756b0dcfb574f6179f0089e52b174ccdbd04123eeb6d70daeabd8513fcba6be0bc2b45ca9a69802dae11cc4d9ff6053b3a87fd8b0c6bf72fffc3b81167f73cca2b3fd656c5d353c8defca8a76e2ad535f984870a590af4e28fed5c5a125bf360747c5e7742e7813d1bd39b5498c8eb6ba72f267eda034314fdbc596f6b967a0ef8be5231d364e634444c84e64bd7919425171016fcd9bb05f01c58a303dee28241f6e860fc3aac3d92aad7dac2801ce79a3b41a0e1f1509fc0d86e96d94edb18616c000152490f64561713102128990fedd3a5fa642f2ff22dc11bc4dc5b209986a0c3e4eb2bdfdd40e9fdf246f702441cac058dd8d0d51eb0796e2bea2ce1b37b2a2f468505e1f8980a9f66d719df034a6fbbd2f9585991d259678fb9a4aebdc465d22c240351ed44abffbdd11b79a706fdf7c40158d3da87f68d7bd557191a8016b5b899c07bf1b87590feb4fa4203feea9a2a7a73ec224813a12b7a21e5dc93fcde4f0a7620f570d31fe27e9b8d65b74db7dc18a5e51adc42d7805d4661938"

    // MARK: - Create Tests

    // Test 1: Create with block node endpoint → success, non-zero registeredNodeId
    internal func test_CreateWithBlockNodeEndpoint() async throws {
        // Given
        let adminKey = PrivateKey.generateEd25519()
        let endpoint = RegisteredServiceEndpoint.blockNode(
            address: .ipAddress(Data([127, 0, 0, 1])),
            port: 8080,
            requiresTls: true,
            endpointApi: .subscribeStream
        )

        // When
        let receipt = try await RegisteredNodeCreateTransaction()
            .adminKey(.single(adminKey.publicKey))
            .addServiceEndpoint(endpoint)
            .freezeWith(testEnv.client)
            .sign(adminKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        XCTAssertEqual(receipt.status, .success)
        let registeredNodeId = try XCTUnwrap(receipt.registeredNodeId)
        XCTAssertNotEqual(registeredNodeId, 0)

        // Cleanup
        _ = try await RegisteredNodeDeleteTransaction()
            .registeredNodeId(registeredNodeId)
            .freezeWith(testEnv.client)
            .sign(adminKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    // Test 2: Create with mirror node endpoint → success
    internal func test_CreateWithMirrorNodeEndpoint() async throws {
        // Given
        let adminKey = PrivateKey.generateEd25519()
        let endpoint = RegisteredServiceEndpoint.mirrorNode(
            address: .domainName("mirror.example.com"),
            port: 443,
            requiresTls: true
        )

        // When
        let receipt = try await RegisteredNodeCreateTransaction()
            .adminKey(.single(adminKey.publicKey))
            .addServiceEndpoint(endpoint)
            .freezeWith(testEnv.client)
            .sign(adminKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        XCTAssertEqual(receipt.status, .success)
        let registeredNodeId = try XCTUnwrap(receipt.registeredNodeId)

        // Cleanup
        _ = try await RegisteredNodeDeleteTransaction()
            .registeredNodeId(registeredNodeId)
            .freezeWith(testEnv.client)
            .sign(adminKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    // Test 3: Create with RPC relay endpoint → success
    internal func test_CreateWithRpcRelayEndpoint() async throws {
        // Given
        let adminKey = PrivateKey.generateEd25519()
        let endpoint = RegisteredServiceEndpoint.rpcRelay(
            address: .domainName("rpc.example.com"),
            port: 443,
            requiresTls: true
        )

        // When
        let receipt = try await RegisteredNodeCreateTransaction()
            .adminKey(.single(adminKey.publicKey))
            .addServiceEndpoint(endpoint)
            .freezeWith(testEnv.client)
            .sign(adminKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        XCTAssertEqual(receipt.status, .success)
        let registeredNodeId = try XCTUnwrap(receipt.registeredNodeId)

        // Cleanup
        _ = try await RegisteredNodeDeleteTransaction()
            .registeredNodeId(registeredNodeId)
            .freezeWith(testEnv.client)
            .sign(adminKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    // Test 4: Create with mixed endpoint types → success, all endpoints stored
    internal func test_CreateWithMixedEndpointTypes() async throws {
        // Given
        let adminKey = PrivateKey.generateEd25519()
        let blockEndpoint = RegisteredServiceEndpoint.blockNode(
            address: .ipAddress(Data([192, 168, 1, 1])),
            port: 8080,
            requiresTls: true,
            endpointApi: .publish
        )
        let mirrorEndpoint = RegisteredServiceEndpoint.mirrorNode(
            address: .domainName("mirror.example.com"),
            port: 443,
            requiresTls: true
        )
        let rpcEndpoint = RegisteredServiceEndpoint.rpcRelay(
            address: .domainName("rpc.example.com"),
            port: 8545,
            requiresTls: false
        )

        // When
        let receipt = try await RegisteredNodeCreateTransaction()
            .adminKey(.single(adminKey.publicKey))
            .addServiceEndpoint(blockEndpoint)
            .addServiceEndpoint(mirrorEndpoint)
            .addServiceEndpoint(rpcEndpoint)
            .freezeWith(testEnv.client)
            .sign(adminKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        XCTAssertEqual(receipt.status, .success)
        let registeredNodeId = try XCTUnwrap(receipt.registeredNodeId)

        // Cleanup
        _ = try await RegisteredNodeDeleteTransaction()
            .registeredNodeId(registeredNodeId)
            .freezeWith(testEnv.client)
            .sign(adminKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    // Test 5: Create with description → success, receipt non-zero
    internal func test_CreateWithDescription() async throws {
        // Given
        let adminKey = PrivateKey.generateEd25519()
        let endpoint = RegisteredServiceEndpoint.blockNode(
            address: .ipAddress(Data([10, 0, 0, 1])),
            port: 7890,
            requiresTls: true,
            endpointApi: .status
        )

        // When
        let receipt = try await RegisteredNodeCreateTransaction()
            .adminKey(.single(adminKey.publicKey))
            .description("My Block Node")
            .addServiceEndpoint(endpoint)
            .freezeWith(testEnv.client)
            .sign(adminKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        XCTAssertEqual(receipt.status, .success)
        let registeredNodeId = try XCTUnwrap(receipt.registeredNodeId)
        XCTAssertNotEqual(registeredNodeId, 0)

        // Cleanup
        _ = try await RegisteredNodeDeleteTransaction()
            .registeredNodeId(registeredNodeId)
            .freezeWith(testEnv.client)
            .sign(adminKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    // Test 6: Create without admin key → failure
    internal func test_CreateWithoutAdminKeyFails() async throws {
        // Given / When / Then
        await assertThrowsHErrorAsync(
            try await RegisteredNodeCreateTransaction()
                .addServiceEndpoint(
                    .blockNode(
                        address: .ipAddress(Data([127, 0, 0, 1])),
                        port: 8080,
                        requiresTls: true,
                        endpointApi: .other
                    )
                )
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        )
    }

    // Test 7: Create with empty service endpoints → failure
    internal func test_CreateWithEmptyEndpointsFails() async throws {
        // Given
        let adminKey = PrivateKey.generateEd25519()

        // When / Then
        await assertThrowsHErrorAsync(
            try await RegisteredNodeCreateTransaction()
                .adminKey(.single(adminKey.publicKey))
                .freezeWith(testEnv.client)
                .sign(adminKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        )
    }

    // MARK: - Update Tests

    // Test 8: Update description → success
    internal func test_UpdateDescription() async throws {
        // Given
        let adminKey = PrivateKey.generateEd25519()
        let registeredNodeId = try await createTestRegisteredNode(adminKey: adminKey)
        defer { Task { try? await deleteTestRegisteredNode(registeredNodeId, adminKey: adminKey) } }

        // When
        let receipt = try await RegisteredNodeUpdateTransaction()
            .registeredNodeId(registeredNodeId)
            .description("My Updated Block Node")
            .freezeWith(testEnv.client)
            .sign(adminKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        XCTAssertEqual(receipt.status, .success)
    }

    // Test 9: Update service endpoints (replace) → success
    internal func test_UpdateServiceEndpoints() async throws {
        // Given
        let adminKey = PrivateKey.generateEd25519()
        let registeredNodeId = try await createTestRegisteredNode(adminKey: adminKey)
        defer { Task { try? await deleteTestRegisteredNode(registeredNodeId, adminKey: adminKey) } }

        let newEndpoint = RegisteredServiceEndpoint.blockNode(
            address: .domainName("newblock.example.com"),
            port: 9000,
            requiresTls: true,
            endpointApi: .stateProof
        )

        // When
        let receipt = try await RegisteredNodeUpdateTransaction()
            .registeredNodeId(registeredNodeId)
            .addServiceEndpoint(newEndpoint)
            .freezeWith(testEnv.client)
            .sign(adminKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        XCTAssertEqual(receipt.status, .success)
    }

    // Test 10: Update admin key (both old and new sign) → success
    internal func test_UpdateAdminKeyWithBothSignatures() async throws {
        // Given
        let oldAdminKey = PrivateKey.generateEd25519()
        let newAdminKey = PrivateKey.generateEd25519()
        let registeredNodeId = try await createTestRegisteredNode(adminKey: oldAdminKey)
        defer { Task { try? await deleteTestRegisteredNode(registeredNodeId, adminKey: newAdminKey) } }

        // When
        let receipt = try await RegisteredNodeUpdateTransaction()
            .registeredNodeId(registeredNodeId)
            .adminKey(.single(newAdminKey.publicKey))
            .freezeWith(testEnv.client)
            .sign(oldAdminKey)
            .sign(newAdminKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        XCTAssertEqual(receipt.status, .success)
    }

    // Test 11: Update admin key (only old key signs) → failure with INVALID_SIGNATURE
    internal func test_UpdateAdminKeyWithOnlyOldSignatureFails() async throws {
        // Given
        let oldAdminKey = PrivateKey.generateEd25519()
        let newAdminKey = PrivateKey.generateEd25519()
        let registeredNodeId = try await createTestRegisteredNode(adminKey: oldAdminKey)
        defer { Task { try? await deleteTestRegisteredNode(registeredNodeId, adminKey: oldAdminKey) } }

        // When / Then
        await assertReceiptStatus(
            try await RegisteredNodeUpdateTransaction()
                .registeredNodeId(registeredNodeId)
                .adminKey(.single(newAdminKey.publicKey))
                .freezeWith(testEnv.client)
                .sign(oldAdminKey)
                // Note: new admin key does NOT sign
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )
    }

    // Test 12: Update non-existent registeredNodeId → failure
    internal func test_UpdateNonExistentRegisteredNodeFails() async throws {
        // Given
        let adminKey = PrivateKey.generateEd25519()
        let nonExistentId: UInt64 = 999_999_999

        // When / Then
        await assertThrowsHErrorAsync(
            try await RegisteredNodeUpdateTransaction()
                .registeredNodeId(nonExistentId)
                .description("won't apply")
                .freezeWith(testEnv.client)
                .sign(adminKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        )
    }

    // MARK: - Delete Tests

    // Test 13: Delete registered node signed by admin key → success
    internal func test_DeleteRegisteredNode() async throws {
        // Given
        let adminKey = PrivateKey.generateEd25519()
        let registeredNodeId = try await createTestRegisteredNode(adminKey: adminKey)

        // When
        let receipt = try await RegisteredNodeDeleteTransaction()
            .registeredNodeId(registeredNodeId)
            .freezeWith(testEnv.client)
            .sign(adminKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        XCTAssertEqual(receipt.status, .success)
    }

    // Test 14: Delete an already-deleted node → failure
    internal func test_DeleteAlreadyDeletedNodeFails() async throws {
        // Given
        let adminKey = PrivateKey.generateEd25519()
        let registeredNodeId = try await createTestRegisteredNode(adminKey: adminKey)

        // First deletion should succeed
        _ = try await RegisteredNodeDeleteTransaction()
            .registeredNodeId(registeredNodeId)
            .freezeWith(testEnv.client)
            .sign(adminKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // When / Then: second deletion should fail
        await assertThrowsHErrorAsync(
            try await RegisteredNodeDeleteTransaction()
                .registeredNodeId(registeredNodeId)
                .freezeWith(testEnv.client)
                .sign(adminKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        )
    }

    // Test 15: Delete a non-existent registeredNodeId → failure
    internal func test_DeleteNonExistentRegisteredNodeFails() async throws {
        // Given
        let adminKey = PrivateKey.generateEd25519()
        let nonExistentId: UInt64 = 999_999_998

        // When / Then
        await assertThrowsHErrorAsync(
            try await RegisteredNodeDeleteTransaction()
                .registeredNodeId(nonExistentId)
                .freezeWith(testEnv.client)
                .sign(adminKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        )
    }

    // MARK: - Consensus Node Association Tests

    // Test 16: Create consensus node with associatedRegisteredNodes → success
    internal func test_NodeCreateWithAssociatedRegisteredNode() async throws {
        // Given: create a registered node first
        let registeredNodeAdminKey = PrivateKey.generateEd25519()
        let registeredNodeId = try await createTestRegisteredNode(adminKey: registeredNodeAdminKey)
        defer { Task { try? await deleteTestRegisteredNode(registeredNodeId, adminKey: registeredNodeAdminKey) } }

        let accountKey = PrivateKey.generateEd25519()
        let accountId = try await createUnmanagedAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(accountKey.publicKey))
                .initialBalance(Hbar(1)),
            useAdminClient: true
        )
        let validGossipCert = Data(hexEncoded: Self.validGossipCertDerHex)!
        let nodeAdminKey = PrivateKey.generateEd25519()

        // When
        let receipt = try await NodeCreateTransaction()
            .accountId(accountId)
            .gossipEndpoints([Endpoint(ipAddress: nil, port: 1234, domainName: "1234.com")])
            .serviceEndpoints([Endpoint(ipAddress: nil, port: 5678, domainName: "5678.com")])
            .gossipCaCertificate(validGossipCert)
            .adminKey(.single(nodeAdminKey.publicKey))
            .addAssociatedRegisteredNode(registeredNodeId)
            .freezeWith(testEnv.adminClient)
            .sign(nodeAdminKey)
            .execute(testEnv.adminClient)
            .getReceipt(testEnv.adminClient)

        // Then
        XCTAssertEqual(receipt.status, .success)
    }

    // Test 17: Update consensus node with associatedRegisteredNodes → success
    internal func test_NodeUpdateWithAssociatedRegisteredNode() async throws {
        // Given: create a registered node first
        let registeredNodeAdminKey = PrivateKey.generateEd25519()
        let registeredNodeId = try await createTestRegisteredNode(adminKey: registeredNodeAdminKey)
        defer { Task { try? await deleteTestRegisteredNode(registeredNodeId, adminKey: registeredNodeAdminKey) } }

        // When: update an existing consensus node (node 0) to associate the registered node
        let receipt = try await NodeUpdateTransaction()
            .nodeId(0)
            .addAssociatedRegisteredNode(registeredNodeId)
            .execute(testEnv.adminClient)
            .getReceipt(testEnv.adminClient)

        // Then
        XCTAssertEqual(receipt.status, .success)

        // Reset: clear the association
        _ = try await NodeUpdateTransaction()
            .nodeId(0)
            .clearAssociatedRegisteredNodes()
            .execute(testEnv.adminClient)
            .getReceipt(testEnv.adminClient)
    }

    // MARK: - Endpoint Address Conversion Test

    // Test 18: Update endpoint from IP address to domain name → success
    internal func test_UpdateEndpointFromIpToDomainName() async throws {
        // Given
        let adminKey = PrivateKey.generateEd25519()
        let registeredNodeId = try await createTestRegisteredNode(adminKey: adminKey)
        defer { Task { try? await deleteTestRegisteredNode(registeredNodeId, adminKey: adminKey) } }

        let domainEndpoint = RegisteredServiceEndpoint.blockNode(
            address: .domainName("updated.example.com"),
            port: 9090,
            requiresTls: true,
            endpointApi: .status
        )

        // When
        let receipt = try await RegisteredNodeUpdateTransaction()
            .registeredNodeId(registeredNodeId)
            .addServiceEndpoint(domainEndpoint)
            .freezeWith(testEnv.client)
            .sign(adminKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        XCTAssertEqual(receipt.status, .success)
    }

    // MARK: - Helpers

    /// Create a registered node with an IP-based block node endpoint and return its ID.
    private func createTestRegisteredNode(adminKey: PrivateKey) async throws -> UInt64 {
        let receipt = try await RegisteredNodeCreateTransaction()
            .adminKey(.single(adminKey.publicKey))
            .addServiceEndpoint(
                .blockNode(
                    address: .ipAddress(Data([127, 0, 0, 1])),
                    port: 8080,
                    requiresTls: true,
                    endpointApi: .subscribeStream
                )
            )
            .freezeWith(testEnv.client)
            .sign(adminKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        return try XCTUnwrap(receipt.registeredNodeId)
    }

    private func deleteTestRegisteredNode(_ registeredNodeId: UInt64, adminKey: PrivateKey) async throws {
        _ = try await RegisteredNodeDeleteTransaction()
            .registeredNodeId(registeredNodeId)
            .freezeWith(testEnv.client)
            .sign(adminKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }
}

extension Data {
    fileprivate init?(hexEncoded: String) {
        let chars = Array(hexEncoded.utf8)
        guard chars.count % 2 == 0 else { return nil }

        var arr: [UInt8] = []
        arr.reserveCapacity(chars.count / 2)

        func nibble(_ c: UInt8) -> UInt8? {
            switch c {
            case 0x30...0x39: return c - 0x30
            case 0x41...0x46: return c - 0x41 + 10
            case 0x61...0x66: return c - 0x61 + 10
            default: return nil
            }
        }

        for idx in stride(from: 0, to: chars.count, by: 2) {
            guard let hi = nibble(chars[idx]), let lo = nibble(chars[idx + 1]) else { return nil }
            arr.append(hi << 4 | lo)
        }
        self.init(arr)
    }
}
