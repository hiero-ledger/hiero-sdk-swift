// SPDX-License-Identifier: Apache-2.0

import HieroExampleUtilities
import HieroTestSupport
import XCTest

@testable import Hiero

internal class TopicMessageSubmitTransactionIntegrationTests: HieroIntegrationTestCase {
    internal func test_Basic() async throws {
        // Given
        let topicId = try await createStandardTopic()

        // When
        _ = try await TopicMessageSubmitTransaction()
            .topicId(topicId)
            .message("Hello, from HCS!".data(using: .utf8)!)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        let info = try await TopicInfoQuery(topicId: topicId).execute(testEnv.client)
        assertStandardTopicInfo(info, topicId: topicId)
        XCTAssertEqual(info.sequenceNumber, 1)
    }

    internal func test_LargeMessage() async throws {
        // Given
        let bigContents = Resources.bigContents.data(using: .utf8)!
        let topicId = try await createStandardTopic()

        // When
        let responses = try await TopicMessageSubmitTransaction()
            .topicId(topicId)
            .maxChunks(15)
            .message(bigContents)
            .executeAll(testEnv.client)

        for response in responses {
            _ = try await response.getReceipt(testEnv.client)
        }

        // Then
        let info = try await TopicInfoQuery(topicId: topicId).execute(testEnv.client)
        assertStandardTopicInfo(info, topicId: topicId)
        XCTAssertEqual(info.sequenceNumber, 14)
    }

    internal func test_MissingTopicIdFails() async throws {
        // Given
        let bigContents = Resources.bigContents.data(using: .utf8)!

        // When / Then
        await assertPrecheckStatus(
            try await TopicMessageSubmitTransaction()
                .maxChunks(15)
                .message(bigContents)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidTopicID
        )
    }

    internal func test_MissingMessageFails() async throws {
        // Given
        let topicId = try await createStandardTopic()

        // When / Then
        await assertPrecheckStatus(
            try await TopicMessageSubmitTransaction()
                .topicId(topicId)
                .execute(testEnv.client),
            .invalidTopicMessage
        )
    }

    internal func test_ChargesHbarFeeWithLimitsApplied() async throws {
        // Given
        let hbarAmount: UInt64 = 100_000_000
        let privateKey = PrivateKey.generateEcdsa()
        let customFixedFee = CustomFixedFee(hbarAmount / 2, testEnv.operator.accountId)

        let topicId = try await createTopic(
            TopicCreateTransaction()
                .maxTransactionFee(Hbar(50))
                .adminKey(.single(testEnv.operator.privateKey.publicKey))
                .feeScheduleKey(.single(testEnv.operator.privateKey.publicKey))
                .addCustomFee(customFixedFee),
            adminKey: testEnv.operator.privateKey
        )

        let accountId = try await createAccount(
            AccountCreateTransaction()
                .initialBalance(TestConstants.testSmallHbarBalance)
                .keyWithoutAlias(Key.single(privateKey.publicKey)),
            key: privateKey
        )

        let payerClient = try Client.forNetwork(testEnv.client.network)
            .setOperator(accountId, privateKey)

        // When
        _ = try await TopicMessageSubmitTransaction()
            .topicId(topicId)
            .message(Data("Hello, Hedera™ hashgraph!".utf8))
            .execute(payerClient)
            .getReceipt(payerClient)

        // Then
        let accountInfo = try await AccountBalanceQuery()
            .accountId(accountId)
            .execute(testEnv.client)

        XCTAssertLessThan(accountInfo.hbars.toTinybars(), Int64(hbarAmount / 2))
    }

    internal func test_ExemptsFeeExemptKeysFromHbarFees() async throws {
        // Given
        let hbarAmount: UInt64 = 100_000_000
        let feeExemptKey1 = PrivateKey.generateEcdsa()
        let feeExemptKey2 = PrivateKey.generateEcdsa()

        let customFixedFee = CustomFixedFee(hbarAmount / 2, testEnv.operator.accountId)

        let topicId = try await createTopic(
            try TopicCreateTransaction()
                .maxTransactionFee(Hbar(50))
                .adminKey(.single(testEnv.operator.privateKey.publicKey))
                .feeScheduleKey(.single(testEnv.operator.privateKey.publicKey))
                .feeExemptKeys([.single(feeExemptKey1.publicKey), .single(feeExemptKey2.publicKey)])
                .addCustomFee(customFixedFee)
                .freezeWith(testEnv.client)
                .sign(testEnv.operator.privateKey),
            adminKey: testEnv.operator.privateKey
        )

        let payerAccountId = try await createAccount(
            AccountCreateTransaction()
                .initialBalance(TestConstants.testSmallHbarBalance)
                .keyWithoutAlias(Key.single(feeExemptKey1.publicKey)),
            key: feeExemptKey1
        )

        let payerClient = try Client.forNetwork(testEnv.client.network)
            .setOperator(payerAccountId, feeExemptKey1)

        // When
        _ = try await TopicMessageSubmitTransaction()
            .topicId(topicId)
            .message(Data("Hello, Hedera™ hashgraph!".utf8))
            .execute(payerClient)
            .getReceipt(payerClient)

        // Then
        let accountInfo = try await AccountBalanceQuery()
            .accountId(payerAccountId)
            .execute(testEnv.client)

        // Account should have more than half the initial amount because they were exempt from the custom fee
        XCTAssertGreaterThan(accountInfo.hbars.toTinybars(), Int64(hbarAmount / 2))
    }
}
