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

    internal func test_DecodeHexRegressionTest() throws {
        // Given
        let transactionBytes = Data(
            hexEncoded:
                """
                2ac2010a580a130a0b08d38f8f880610a09be91512041899e11c120218041880\
                c2d72f22020878da01330a0418a5a12012103030303030303136323736333737\
                31351a190a130a0b08d38f8f880610a09be91512041899e11c1001180112660a\
                640a20603edaec5d1c974c92cb5bee7b011310c3b84b13dc048424cd6ef146d6\
                a0d4a41a40b6a08f310ee29923e5868aac074468b2bde05da95a806e2f4a4f45\
                2177f129ca0abae7831e595b5beaa1c947e2cb71201642bab33fece5184b0454\
                7afc40850a
                """
        )!

        // When
        let transaction = try Transaction.fromBytes(transactionBytes)

        // Then
        _ = try XCTUnwrap(transaction.transactionId)
    }

    internal func disabledTestChargesHbarFeeWithLimitsApplied() async throws {
        // Given
        let hbarAmount: UInt64 = 100_000_000
        let privateKey = PrivateKey.generateEcdsa()
        let customFixedFee = CustomFixedFee(hbarAmount / 2, testEnv.operator.accountId)

        let topicId = try await createTopic(
            TopicCreateTransaction()
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

        testEnv.client.setOperator(accountId, privateKey)

        // When
        _ = try await TopicMessageSubmitTransaction()
            .topicId(topicId)
            .message(Data("Hello, Hedera™ hashgraph!".utf8))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        testEnv.client.setOperator(testEnv.operator.accountId, PrivateKey.generateEcdsa())

        // Then
        let accountInfo = try await AccountBalanceQuery()
            .accountId(accountId)
            .execute(testEnv.client)

        XCTAssertLessThan(accountInfo.hbars.toTinybars(), Int64(hbarAmount / 2))
    }

    // This test is to ensure that the fee exempt keys are exempted from the custom fee
    internal func disabledTestExemptsFeeExemptKeysFromHbarFees() async throws {
        // Given
        let hbarAmount: UInt64 = 100_000_000
        let feeExemptKey1 = PrivateKey.generateEcdsa()
        let feeExemptKey2 = PrivateKey.generateEcdsa()

        let customFixedFee = CustomFixedFee(hbarAmount / 2, testEnv.operator.accountId)

        let topicId = try await createTopic(
            try TopicCreateTransaction()
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

        testEnv.client.setOperator(payerAccountId, feeExemptKey1)

        // When
        _ = try await TopicMessageSubmitTransaction()
            .topicId(topicId)
            .message(Data("Hello, Hedera™ hashgraph!".utf8))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        testEnv.client.setOperator(payerAccountId, PrivateKey.generateEcdsa())

        // Then
        let accountInfo = try await AccountBalanceQuery()
            .accountId(payerAccountId)
            .execute(testEnv.client)

        XCTAssertGreaterThan(accountInfo.hbars.toTinybars(), Int64(hbarAmount / 2))
    }
}
