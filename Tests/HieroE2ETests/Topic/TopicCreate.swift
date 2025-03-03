/*
 * ‌
 * Hedera Swift SDK
 * ​
 * Copyright (C) 2022 - 2024 Hedera Hashgraph, LLC
 * ​
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ‍
 */

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

    internal func testFieldless() async throws {
        let testEnv = try TestEnvironment.nonFree

        let receipt = try await TopicCreateTransaction()
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try XCTUnwrap(receipt.topicId)
    }

    internal func testCreatesAndUpdatesRevenueGeneratingTopic() async throws {
        let testEnv = try TestEnvironment.nonFree

        // Generate fee exempt keys
        let feeExemptKeys = [PrivateKey.generateEcdsa(), PrivateKey.generateEcdsa()]

        // Create first token
        let token1 = try await FungibleToken.create(testEnv)
        let token2 = try await FungibleToken.create(testEnv)

        // Create custom fixed fees
        let customFixedFees = [
            CustomFixedFee(1, token1.id, testEnv.operator.accountId),
            CustomFixedFee(2, token2.id, testEnv.operator.accountId),
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

        // Get Topic Info
        let info = try await TopicInfoQuery()
            .topicId(topicId)
            .execute(testEnv.client)

        XCTAssertEqual(info.feeScheduleKey?.toBytes(), Key.single(testEnv.operator.privateKey.publicKey).toBytes())

        // Validate fee exempt keys
        for (index, key) in feeExemptKeys.enumerated() {
            XCTAssertEqual(info.feeExemptKeys[index].toBytes(), Key.single(key.publicKey).toBytes())
        }

        // Validate custom fees
        for (index, fee) in customFixedFees.enumerated() {
            XCTAssertEqual(info.customFees[index].amount, fee.amount)
            XCTAssertEqual(info.customFees[index].denominatingTokenId, fee.denominatingTokenId)
        }

        // Update the revenue-generating topic
        let newFeeExemptKeys = [PrivateKey.generateEcdsa(), PrivateKey.generateEcdsa()]
        let newFeeScheduleKey = PrivateKey.generateEcdsa()

        // Create new tokens for updated fees
        let newToken1 = try await FungibleToken.create(testEnv)
        let newToken2 = try await FungibleToken.create(testEnv)

        let newCustomFixedFees = [
            CustomFixedFee(3, newToken1.id, testEnv.operator.accountId),
            CustomFixedFee(4, newToken2.id, testEnv.operator.accountId),
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

        // Test duplicate fee exempt keys
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

        print("feeExemptKeyListExceedingLimit count: \(feeExemptKeyListExceedingLimit.count)")

        await assertThrowsHErrorAsync(
            try await TopicCreateTransaction()
                .adminKey(.single(testEnv.operator.privateKey.publicKey))
                .feeExemptKeys(feeExemptKeyListExceedingLimit)
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
}
