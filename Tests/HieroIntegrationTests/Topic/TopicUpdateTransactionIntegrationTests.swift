// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal class TopicUpdateTransactionIntegrationTests: HieroIntegrationTestCase {
    internal func test_Basic() async throws {
        // Given
        let topicId = try await createStandardTopic()

        // When
        _ = try await TopicUpdateTransaction()
            .topicId(topicId)
            .clearAutoRenewAccountId()
            .topicMemo("hello")
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        let info = try await TopicInfoQuery(topicId: topicId).execute(testEnv.client)
        XCTAssertEqual(info.topicMemo, "hello")
        XCTAssertEqual(info.autoRenewAccountId, nil)
    }

    internal func test_CreatesAndUpdatesRevenueGeneratingTopic() async throws {
        // Given
        let feeExemptKeys = [PrivateKey.generateEcdsa(), PrivateKey.generateEcdsa()]
        let tokenId1 = try await createToken(
            TokenCreateTransaction()
                .name("Test Token")
                .symbol("FT")
                .treasuryAccountId(testEnv.operator.accountId)
                .initialSupply(1_000_000)
                .decimals(2)
                .adminKey(.single(testEnv.operator.privateKey.publicKey))
                .supplyKey(.single(testEnv.operator.privateKey.publicKey)),
            adminKey: testEnv.operator.privateKey
        )
        let tokenId2 = try await createToken(
            TokenCreateTransaction()
                .name("Test Token")
                .symbol("FT")
                .treasuryAccountId(testEnv.operator.accountId)
                .initialSupply(1_000_000)
                .decimals(2)
                .adminKey(.single(testEnv.operator.privateKey.publicKey))
                .supplyKey(.single(testEnv.operator.privateKey.publicKey)),
            adminKey: testEnv.operator.privateKey
        )

        let customFixedFees = [
            CustomFixedFee(1, testEnv.operator.accountId, tokenId1),
            CustomFixedFee(2, testEnv.operator.accountId, tokenId2),
        ]

        let topicId = try await createTopic(
            TopicCreateTransaction()
                .maxTransactionFee(Hbar(50))
                .feeScheduleKey(.single(testEnv.operator.privateKey.publicKey))
                .submitKey(.single(testEnv.operator.privateKey.publicKey))
                .adminKey(.single(testEnv.operator.privateKey.publicKey))
                .feeExemptKeys(feeExemptKeys.map { .single($0.publicKey) })
                .customFees(customFixedFees),
            adminKey: testEnv.operator.privateKey
        )

        let newFeeExemptKeys = [PrivateKey.generateEcdsa(), PrivateKey.generateEcdsa()]
        let newFeeScheduleKey = PrivateKey.generateEcdsa()

        let newToken1 = try await createToken(
            TokenCreateTransaction()
                .name("Test Token")
                .symbol("FT")
                .treasuryAccountId(testEnv.operator.accountId)
                .initialSupply(1_000_000)
                .decimals(2)
                .adminKey(.single(testEnv.operator.privateKey.publicKey))
                .supplyKey(.single(testEnv.operator.privateKey.publicKey)),
            adminKey: testEnv.operator.privateKey
        )
        let newToken2 = try await createToken(
            TokenCreateTransaction()
                .name("Test Token")
                .symbol("FT")
                .treasuryAccountId(testEnv.operator.accountId)
                .initialSupply(1_000_000)
                .decimals(2)
                .adminKey(.single(testEnv.operator.privateKey.publicKey))
                .supplyKey(.single(testEnv.operator.privateKey.publicKey)),
            adminKey: testEnv.operator.privateKey
        )

        let newCustomFixedFees = [
            CustomFixedFee(3, testEnv.operator.accountId, newToken1),
            CustomFixedFee(4, testEnv.operator.accountId, newToken2),
        ]

        // When
        _ = try await TopicUpdateTransaction()
            .topicId(topicId)
            .maxTransactionFee(Hbar(50))
            .feeExemptKeys(newFeeExemptKeys.map { .single($0.publicKey) })
            .feeScheduleKey(.single(newFeeScheduleKey.publicKey))
            .customFees(newCustomFixedFees)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        let updatedInfo = try await TopicInfoQuery()
            .topicId(topicId)
            .execute(testEnv.client)

        XCTAssertEqual(updatedInfo.feeScheduleKey?.toBytes(), Key.single(newFeeScheduleKey.publicKey).toBytes())

        for (index, key) in newFeeExemptKeys.enumerated() {
            XCTAssertEqual(updatedInfo.feeExemptKeys[index].toBytes(), Key.single(key.publicKey).toBytes())
        }

        for (index, fee) in newCustomFixedFees.enumerated() {
            XCTAssertEqual(updatedInfo.customFees[index].amount, fee.amount)
            XCTAssertEqual(updatedInfo.customFees[index].denominatingTokenId, fee.denominatingTokenId)
        }
    }

    internal func test_UpdateFeeScheduleKeyWithoutPermissionFails() async throws {
        // Given
        let topicId = try await createTopicWithOperatorAdmin()
        let feeScheduleKey = PrivateKey.generateEd25519()

        // When / Then
        await assertReceiptStatus(
            try await TopicUpdateTransaction()
                .topicId(topicId)
                .feeScheduleKey(.single(feeScheduleKey.publicKey))
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .feeScheduleKeyCannotBeUpdated
        )
    }

    internal func test_UpdateCustomFeesWithoutFeeScheduleKeyFails() async throws {
        // Given
        let topicId = try await createTopic(
            TopicCreateTransaction()
                .adminKey(.single(testEnv.operator.privateKey.publicKey)),
            adminKey: testEnv.operator.privateKey
        )

        let denominatingTokenId1 = try await createToken(
            TokenCreateTransaction()
                .name("Test Token 1")
                .symbol("FT1")
                .treasuryAccountId(testEnv.operator.accountId)
                .initialSupply(1_000_000)
                .decimals(2)
                .adminKey(.single(testEnv.operator.privateKey.publicKey))
                .supplyKey(.single(testEnv.operator.privateKey.publicKey)),
            adminKey: testEnv.operator.privateKey
        )
        let denominatingTokenId2 = try await createToken(
            TokenCreateTransaction()
                .name("Test Token 2")
                .symbol("FT2")
                .treasuryAccountId(testEnv.operator.accountId)
                .initialSupply(1_000_000)
                .decimals(2)
                .adminKey(.single(testEnv.operator.privateKey.publicKey))
                .supplyKey(.single(testEnv.operator.privateKey.publicKey)),
            adminKey: testEnv.operator.privateKey
        )

        let customFixedFees = [
            CustomFixedFee(1, testEnv.operator.accountId, denominatingTokenId1),
            CustomFixedFee(2, testEnv.operator.accountId, denominatingTokenId2),
        ]

        // When / Then
        await assertReceiptStatus(
            try await TopicUpdateTransaction()
                .topicId(topicId)
                .customFees(customFixedFees)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .feeScheduleKeyNotSet
        )
    }
}
