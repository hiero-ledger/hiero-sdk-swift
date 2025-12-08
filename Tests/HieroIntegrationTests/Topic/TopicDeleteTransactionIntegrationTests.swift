// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal class TopicDeleteTransactionIntegrationTests: HieroIntegrationTestCase {
    internal func test_Basic() async throws {
        // Given
        let topicId = try await createUnmanagedTopic(
            TopicCreateTransaction()
                .adminKey(.single(testEnv.operator.privateKey.publicKey))
                .topicMemo(TestConstants.standardTopicMemo)
        )

        // When / Then
        _ = try await TopicDeleteTransaction()
            .topicId(topicId)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    internal func test_ImmutableFails() async throws {
        // Given
        let topicId = try await createImmutableTopic()

        // When / Then
        await assertReceiptStatus(
            try await TopicDeleteTransaction()
                .topicId(topicId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .unauthorized
        )
    }

    internal func test_WrongAdminKeyFails() async throws {
        // Given
        let adminKey = PrivateKey.generateEd25519()
        let topicId = try await createTopic(
            TopicCreateTransaction()
                .adminKey(.single(adminKey.publicKey))
                .sign(adminKey),
            adminKey: adminKey
        )

        // When / Then
        await assertReceiptStatus(
            try await TopicDeleteTransaction()
                .topicId(topicId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )
    }
}
