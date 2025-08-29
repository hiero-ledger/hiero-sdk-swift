// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero
import XCTest

internal class TopicCreate: XCTestCase {
    internal func testBasic() async throws {
        let testEnv = try TestEnvironment.nonFree

        let receipt = try await TopicCreateTransaction()
            .adminKey(.single(testEnv.operator.privateKey.publicKey))
            .topicMemo("[e2e::TopicCreateTransaction]")
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let topicId = try XCTUnwrap(receipt.topicId)

        let topic = Topic(id: topicId)

        try await topic.delete(testEnv)
    }

    internal func disabled_testFieldless() async throws {
        let testEnv = try TestEnvironment.nonFree

        let receipt = try await TopicCreateTransaction()
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try XCTUnwrap(receipt.topicId)
    }

    internal func disabled_testCreatesAndUpdatesRevenueGeneratingTopic() async throws {
        let testEnv = try TestEnvironment.nonFree

        let feeExemptKeys = [PrivateKey.generateEcdsa(), PrivateKey.generateEcdsa()]

        let token1 = try await createToken(testEnv)
        let token2 = try await createToken(testEnv)

        let customFixedFees = [
            CustomFixedFee(1, testEnv.operator.accountId, token1),
            CustomFixedFee(2, testEnv.operator.accountId, token2),
        ]

        // Create revenue-generating topic
        let receipt = try await TopicCreateTransaction()
            .feeScheduleKey(.single(testEnv.operator.privateKey.publicKey))
            .submitKey(.single(testEnv.operator.privateKey.publicKey))
            .adminKey(.single(testEnv.operator.privateKey.publicKey))
            .feeExemptKeys(feeExemptKeys.map { .single($0.publicKey) })
            .customFees(customFixedFees)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let topicId = try XCTUnwrap(receipt.topicId)

        let info = try await TopicInfoQuery()
            .topicId(topicId)
            .execute(testEnv.client)

        XCTAssertEqual(info.feeScheduleKey?.toBytes(), Key.single(testEnv.operator.privateKey.publicKey).toBytes())

        // Update the revenue-generating topic
        let newFeeExemptKeys = [PrivateKey.generateEcdsa(), PrivateKey.generateEcdsa()]
        let newFeeScheduleKey = PrivateKey.generateEcdsa()

        let newToken1 = try await createToken(testEnv)
        let newToken2 = try await createToken(testEnv)

        let newCustomFixedFees = [
            CustomFixedFee(3, testEnv.operator.accountId, newToken1),
            CustomFixedFee(4, testEnv.operator.accountId, newToken2),
        ]

        _ = try await TopicUpdateTransaction()
            .topicId(topicId)
            .feeExemptKeys(newFeeExemptKeys.map { .single($0.publicKey) })
            .feeScheduleKey(.single(newFeeScheduleKey.publicKey))
            .customFees(newCustomFixedFees)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let updatedInfo = try await TopicInfoQuery()
            .topicId(topicId)
            .execute(testEnv.client)

        XCTAssertEqual(updatedInfo.feeScheduleKey?.toBytes(), Key.single(newFeeScheduleKey.publicKey).toBytes())

        // Validate updated fee exempt keys
        for (index, key) in newFeeExemptKeys.enumerated() {
            XCTAssertEqual(updatedInfo.feeExemptKeys[index].toBytes(), Key.single(key.publicKey).toBytes())
        }

        // Validate updated custom fees
        for (index, fee) in newCustomFixedFees.enumerated() {
            XCTAssertEqual(updatedInfo.customFees[index].amount, fee.amount)
            XCTAssertEqual(updatedInfo.customFees[index].denominatingTokenId, fee.denominatingTokenId)
        }
    }

    internal func testCreateRevenueGeneratingTopicWithInvalidFeeExemptKeyFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        let feeExemptKey = PrivateKey.generateEcdsa()
        let feeExemptKeyListWithDuplicates = [Key.single(feeExemptKey.publicKey), Key.single(feeExemptKey.publicKey)]

        await assertThrowsHErrorAsync(
            try await TopicCreateTransaction()
                .adminKey(.single(testEnv.operator.privateKey.publicKey))
                .feeExemptKeys(feeExemptKeyListWithDuplicates)
                .execute(testEnv.client),
            "expected error creating topic with duplicate fee exempt keys"
        ) { error in
            guard case .transactionPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.transactionPreCheckStatus`")
                return
            }

            XCTAssertEqual(status, .feeExemptKeyListContainsDuplicatedKeys)
        }

        // Test exceeding key limit
        let feeExemptKeyListExceedingLimit = (0..<11).map { _ in Key.single(PrivateKey.generateEcdsa().publicKey) }

        await assertThrowsHErrorAsync(
            try await TopicCreateTransaction()
                .adminKey(.single(testEnv.operator.privateKey.publicKey))
                .feeExemptKeys(feeExemptKeyListExceedingLimit)
                .freezeWith(testEnv.client)
                .sign(testEnv.operator.privateKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            "expected error creating topic with too many fee exempt keys"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .maxEntriesForFeeExemptKeyListExceeded)
        }
    }

    internal func disabled_testUpdateFeeScheduleKeyWithoutPermissionFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        let receipt = try await TopicCreateTransaction()
            .adminKey(.single(testEnv.operator.privateKey.publicKey))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let topicId = try XCTUnwrap(receipt.topicId)

        let feeScheduleKey = PrivateKey.generateEd25519()

        await assertThrowsHErrorAsync(
            try await TopicUpdateTransaction()
                .topicId(topicId)
                .feeScheduleKey(.single(feeScheduleKey.publicKey))
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            "expected error updating fee schedule key without permission"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .feeScheduleKeyCannotBeUpdated)
        }
    }

    internal func disabled_testUpdateCustomFeesWithoutFeeScheduleKeyFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        let receipt = try await TopicCreateTransaction()
            .adminKey(.single(testEnv.operator.privateKey.publicKey))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let topicId = try XCTUnwrap(receipt.topicId)

        let denominatingTokenId1 = try await createToken(testEnv)
        let denominatingTokenId2 = try await createToken(testEnv)

        let customFixedFees = [
            CustomFixedFee(1, testEnv.operator.accountId, denominatingTokenId1),
            CustomFixedFee(2, testEnv.operator.accountId, denominatingTokenId2),
        ]

        await assertThrowsHErrorAsync(
            try await TopicUpdateTransaction()
                .topicId(topicId)
                .customFees(customFixedFees)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            "expected error updating custom fees without fee schedule key"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .feeScheduleKeyNotSet)
        }
    }

    internal func testChargesHbarFeeWithLimitsApplied() async throws {
        let testEnv = try TestEnvironment.nonFree
        let hbarAmount: UInt64 = 100_000_000
        let privateKey = PrivateKey.generateEcdsa()

        let customFixedFee = CustomFixedFee(hbarAmount / 2, testEnv.operator.accountId)

        let receipt = try await TopicCreateTransaction()
            .adminKey(.single(testEnv.operator.privateKey.publicKey))
            .feeScheduleKey(.single(testEnv.operator.privateKey.publicKey))
            .addCustomFee(customFixedFee)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let topicId = try XCTUnwrap(receipt.topicId)

        let accountReceipt = try await AccountCreateTransaction()
            .initialBalance(Hbar(1))
            .keyWithoutAlias(Key.single(privateKey.publicKey))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let accountId = try XCTUnwrap(accountReceipt.accountId)

        testEnv.client.setOperator(accountId, privateKey)

        _ = try await TopicMessageSubmitTransaction()
            .topicId(topicId)
            .message(Data("Hello, Hedera™ hashgraph!".utf8))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        testEnv.client.setOperator(testEnv.operator.accountId, PrivateKey.generateEcdsa())

        let accountInfo = try await AccountBalanceQuery()
            .accountId(accountId)
            .execute(testEnv.client)

        XCTAssertLessThan(accountInfo.hbars.toTinybars(), Int64(hbarAmount / 2))
    }

    // This test is to ensure that the fee exempt keys are exempted from the custom fee
    internal func disabled_testExemptsFeeExemptKeysFromHbarFees() async throws {
        let testEnv = try TestEnvironment.nonFree

        let hbarAmount: UInt64 = 100_000_000
        let feeExemptKey1 = PrivateKey.generateEcdsa()
        let feeExemptKey2 = PrivateKey.generateEcdsa()

        let customFixedFee = CustomFixedFee(hbarAmount / 2, testEnv.operator.accountId)

        let receipt = try await TopicCreateTransaction()
            .adminKey(.single(testEnv.operator.privateKey.publicKey))
            .feeScheduleKey(.single(testEnv.operator.privateKey.publicKey))
            .feeExemptKeys([.single(feeExemptKey1.publicKey), .single(feeExemptKey2.publicKey)])
            .addCustomFee(customFixedFee)
            .freezeWith(testEnv.client)
            .sign(testEnv.operator.privateKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let topicId = try XCTUnwrap(receipt.topicId)

        let payerAccountReceipt = try await AccountCreateTransaction()
            .initialBalance(Hbar(1))
            .keyWithoutAlias(Key.single(feeExemptKey1.publicKey))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let payerAccountId = try XCTUnwrap(payerAccountReceipt.accountId)

        testEnv.client.setOperator(payerAccountId, feeExemptKey1)

        _ = try await TopicMessageSubmitTransaction()
            .topicId(topicId)
            .message(Data("Hello, Hedera™ hashgraph!".utf8))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        testEnv.client.setOperator(payerAccountId, PrivateKey.generateEcdsa())

        let accountInfo = try await AccountBalanceQuery()
            .accountId(payerAccountId)
            .execute(testEnv.client)

        XCTAssertGreaterThan(accountInfo.hbars.toTinybars(), Int64(hbarAmount / 2))
    }

    // This test is to ensure that the autoRenewAccountId is automatically assigned to the
    // operator if it is not set
    internal func testAutomaticallyAssignAutoRenewAccountIdOnTopicCreate() async throws {
        let testEnv = try TestEnvironment.nonFree
        let topicReceipt = try await TopicCreateTransaction()
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let topicId = try XCTUnwrap(topicReceipt.topicId)

        let info = try await TopicInfoQuery()
            .topicId(topicId)
            .execute(testEnv.client)

        XCTAssertNotNil(info.autoRenewAccountId)
    }

    internal func disabled_testCreateWithTransactionIdAssignsAutoRenewAccountIdToTransactionIdAccountId() async throws {
        let testEnv = try TestEnvironment.nonFree
        let privateKey = PrivateKey.generateEcdsa()
        let publicKey = privateKey.publicKey

        let accountReceipt = try await AccountCreateTransaction()
            .keyWithoutAlias(Key.single(publicKey))
            .initialBalance(Hbar(10))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let accountId = try XCTUnwrap(accountReceipt.accountId)

        let topicReceipt = try await TopicCreateTransaction()
            .transactionId(TransactionId.generateFrom(accountId))
            .freezeWith(testEnv.client)
            .sign(testEnv.operator.privateKey)
            .sign(privateKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let topicId = try XCTUnwrap(topicReceipt.topicId)

        let topicInfo = try await TopicInfoQuery()
            .topicId(topicId)
            .execute(testEnv.client)

        XCTAssertEqual(topicInfo.autoRenewAccountId, accountId)
    }

    fileprivate func createToken(_ testEnv: NonfreeTestEnvironment) async throws -> TokenId {
        let operatorKey: Key = .single(testEnv.operator.privateKey.publicKey)

        let tokenCreateReceipt = try await TokenCreateTransaction()
            .name("Test Token")
            .symbol("FT")
            .treasuryAccountId(testEnv.operator.accountId)
            .initialSupply(1_000_000)
            .decimals(2)
            .adminKey(operatorKey)
            .supplyKey(operatorKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        return try XCTUnwrap(tokenCreateReceipt.tokenId)
    }
}
