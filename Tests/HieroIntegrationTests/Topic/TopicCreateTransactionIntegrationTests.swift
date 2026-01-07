// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero
import HieroTestSupport
import XCTest

internal class TopicCreateTransactionIntegrationTests: HieroIntegrationTestCase {
    internal func test_Basic() async throws {
        // Given / When
        let topicId = try await createStandardTopic()

        // Then
        let info = try await TopicInfoQuery(topicId: topicId).execute(testEnv.client)
        XCTAssertEqual(info.topicMemo, TestConstants.standardTopicMemo)
    }

    internal func test_Fieldless() async throws {
        // Given / When
        let topicId = try await createImmutableTopic()

        // Then
        XCTAssertNotNil(topicId)
    }

    internal func test_CreateRevenueGeneratingTopicWithInvalidFeeExemptKeyFails() async throws {
        // Given
        let feeExemptKey = PrivateKey.generateEcdsa()
        let feeExemptKeyListWithDuplicates = [Key.single(feeExemptKey.publicKey), Key.single(feeExemptKey.publicKey)]

        // When / Then
        await assertPrecheckStatus(
            try await TopicCreateTransaction()
                .adminKey(.single(testEnv.operator.privateKey.publicKey))
                .feeExemptKeys(feeExemptKeyListWithDuplicates)
                .execute(testEnv.client),
            .feeExemptKeyListContainsDuplicatedKeys
        )
    }

    internal func test_CreateRevenueGeneratingTopicWithTooManyFeeExemptKeyFails() async throws {
        // Given
        let feeExemptKeyListExceedingLimit = (0..<11).map { _ in Key.single(PrivateKey.generateEcdsa().publicKey) }

        // When / Then
        await assertReceiptStatus(
            try await TopicCreateTransaction()
                .adminKey(.single(testEnv.operator.privateKey.publicKey))
                .feeExemptKeys(feeExemptKeyListExceedingLimit)
                .freezeWith(testEnv.client)
                .sign(testEnv.operator.privateKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .maxEntriesForFeeExemptKeyListExceeded
        )
    }

    internal func test_AutomaticallyAssignAutoRenewAccountIdOnTopicCreate() async throws {
        // Given / When
        let topicId = try await createImmutableTopic()

        // Then
        let info = try await TopicInfoQuery(topicId: topicId).execute(testEnv.client)
        XCTAssertNotNil(info.autoRenewAccountId)
    }

    internal func test_CreateWithTransactionIdAssignsAutoRenewAccountIdToTransactionIdAccountId() async throws {
        // Given
        let (accountId, privateKey) = try await createTestAccount(initialBalance: TestConstants.testMediumHbarBalance)
        let adminKey = PrivateKey.generateEcdsa()

        // When
        let topicId = try await createTopic(
            TopicCreateTransaction()
                .transactionId(TransactionId.generateFrom(accountId))
                .adminKey(.single(adminKey.publicKey))
                .freezeWith(testEnv.client)
                .sign(privateKey)
                .sign(adminKey),
            adminKey: adminKey
        )

        // Then
        let topicInfo = try await TopicInfoQuery()
            .topicId(topicId)
            .execute(testEnv.client)
        XCTAssertEqual(topicInfo.autoRenewAccountId, accountId)
    }
}
