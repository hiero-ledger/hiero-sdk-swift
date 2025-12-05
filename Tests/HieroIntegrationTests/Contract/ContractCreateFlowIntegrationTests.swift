// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal final class ContractCreateFlowIntegrationTests: HieroIntegrationTestCase {
    internal func test_Basic() async throws {
        // Given / When
        let receipt = try await standardContractCreateFlow(adminKey: .single(testEnv.operator.privateKey.publicKey))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let contractId = try XCTUnwrap(receipt.contractId)
        await registerContract(contractId, adminKey: testEnv.operator.privateKey)

        // Then
        let info = try await ContractInfoQuery(contractId: contractId).execute(testEnv.client)
        assertStandardContractInfo(
            info,
            contractId: contractId,
            adminKey: .single(testEnv.operator.privateKey.publicKey)
        )
    }

    internal func test_AdminKeyMissingSignatureFails() async throws {
        // Given
        let adminKey = PrivateKey.generateEd25519()

        // When / Then
        await assertReceiptStatus(
            try await standardContractCreateFlow(adminKey: .single(adminKey.publicKey))
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )
    }

    internal func test_AdminKey() async throws {
        // Given
        let adminKey = PrivateKey.generateEd25519()

        // When
        let receipt = try await standardContractCreateFlow(adminKey: .single(adminKey.publicKey))
            .sign(adminKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let contractId = try XCTUnwrap(receipt.contractId)
        await registerContract(contractId, adminKey: adminKey)

        // Then
        let info = try await ContractInfoQuery(contractId: contractId).execute(testEnv.client)
        assertStandardContractInfo(
            info,
            contractId: contractId,
            adminKey: .single(adminKey.publicKey)
        )
    }

    internal func test_AdminKeySignWith() async throws {
        // Given
        let adminKey = PrivateKey.generateEd25519()

        // When
        let receipt = try await standardContractCreateFlow(adminKey: .single(adminKey.publicKey))
            .signWith(adminKey.publicKey, adminKey.sign(_:))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let contractId = try XCTUnwrap(receipt.contractId)
        await registerContract(contractId, adminKey: adminKey)

        // Then
        let info = try await ContractInfoQuery(contractId: contractId).execute(testEnv.client)
        assertStandardContractInfo(
            info,
            contractId: contractId,
            adminKey: .single(adminKey.publicKey)
        )
    }
}
