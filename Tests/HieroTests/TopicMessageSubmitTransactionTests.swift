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

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class TopicMessageSubmitTransactionTests: XCTestCase {
    private static let testAutoRenewAccountId: AccountId = "0.0.5007"
    private static let testAutoRenewPeriod: Duration = .days(1)
    private static let testMessageBytes = Data([0x04, 0x05, 0x06].bytes)

    private static func makeTransaction() throws -> TopicMessageSubmitTransaction {
        try TopicMessageSubmitTransaction()
            .nodeAccountIds(Resources.nodeAccountIds)
            .transactionId(Resources.txId)
            .topicId(Resources.topicId)
            .message(Self.testMessageBytes)
            .freeze()
            .sign(Resources.privateKey)
    }

    internal func testSerialize() throws {
        let tx = try Self.makeTransaction().makeProtoBody()

        assertSnapshot(matching: tx, as: .description)
    }

    internal func testToFromBytes() throws {
        let tx = try Self.makeTransaction()

        let tx2 = try Transaction.fromBytes(tx.toBytes())

        XCTAssertEqual(try tx.makeProtoBody(), try tx2.makeProtoBody())
    }

    internal func testFromProtoBody() throws {
        let protoData = Proto_ConsensusSubmitMessageTransactionBody.with { proto in
            proto.topicID = Resources.topicId.toProtobuf()
            proto.message = Self.testMessageBytes
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.consensusSubmitMessage = protoData
            proto.transactionID = Resources.txId.toProtobuf()
        }

        let tx = try TopicMessageSubmitTransaction(protobuf: protoBody, [protoData])

        XCTAssertEqual(tx.topicId, Resources.topicId)
    }

    internal func testGetSetTopicId() {
        let tx = TopicMessageSubmitTransaction()
        tx.topicId(Resources.topicId)

        XCTAssertEqual(tx.topicId, Resources.topicId)
    }

    internal func testGetSetMessage() {
        let tx = TopicMessageSubmitTransaction()
        tx.message(Self.testMessageBytes)

        XCTAssertEqual(tx.message, Self.testMessageBytes)
    }

    internal func testSetCustomFeeLimits() throws {
        let customFeeLimits = [
            CustomFeeLimit(
                payerId: AccountId("0.0.1"),
                customFees: [
                    CustomFixedFee(1, nil, TokenId("0.0.1"))
                ]),
            CustomFeeLimit(
                payerId: AccountId("0.0.2"),
                customFees: [
                    CustomFixedFee(1, nil, TokenId("0.0.2"))
                ]),
        ]

        let tx = TopicMessageSubmitTransaction()
        tx.customFeeLimits(customFeeLimits)

        XCTAssertEqual(tx.customFeeLimits, customFeeLimits)
    }

    internal func testAddCustomFeeLimitToList() throws {
        let customFeeLimits = [
            CustomFeeLimit(
                payerId: AccountId("0.0.1"),
                customFees: [
                    CustomFixedFee(1, nil, TokenId("0.0.1"))
                ]),
            CustomFeeLimit(
                payerId: AccountId("0.0.2"),
                customFees: [
                    CustomFixedFee(1, nil, TokenId("0.0.2"))
                ]),
        ]

        let customFeeLimitToAdd = CustomFeeLimit(
            payerId: AccountId("0.0.3"),
            customFees: [
                CustomFixedFee(3, nil, TokenId("0.0.3"))
            ])

        var expectedCustomFeeLimits = customFeeLimits
        expectedCustomFeeLimits.append(customFeeLimitToAdd)

        let tx = TopicMessageSubmitTransaction()
            .customFeeLimits(customFeeLimits)
            .addCustomFeeLimit(customFeeLimitToAdd)

        XCTAssertEqual(tx.customFeeLimits, expectedCustomFeeLimits)
    }

    internal func testAddCustomFeeLimitToEmptyList() throws {
        let customFeeLimitToAdd = CustomFeeLimit(
            payerId: AccountId("0.0.3"),
            customFees: [
                CustomFixedFee(3, nil, TokenId("0.0.3"))
            ])

        let tx = TopicMessageSubmitTransaction()
            .customFeeLimits([])
            .addCustomFeeLimit(customFeeLimitToAdd)

        XCTAssertEqual(tx.customFeeLimits, [customFeeLimitToAdd])
    }
}
