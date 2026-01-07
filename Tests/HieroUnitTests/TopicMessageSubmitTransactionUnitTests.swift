// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class TopicMessageSubmitTransactionUnitTests: HieroUnitTestCase, TransactionTestable {
    typealias TransactionType = TopicMessageSubmitTransaction

    private static let testAutoRenewAccountId: AccountId = "0.0.5007"
    private static let testAutoRenewPeriod: Duration = .days(1)
    private static let testMessageBytes = Data([0x04, 0x05, 0x06].bytes)

    static func makeTransaction() throws -> TopicMessageSubmitTransaction {
        try TopicMessageSubmitTransaction()
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .topicId(TestConstants.topicId)
            .message(Self.testMessageBytes)
            .freeze()
            .sign(TestConstants.privateKey)
    }

    internal func test_Serialize() throws {
        try assertTransactionSerializes()
    }

    internal func test_ToFromBytes() throws {
        try assertTransactionRoundTrips()
    }

    internal func test_FromProtoBody() throws {
        let protoData = Proto_ConsensusSubmitMessageTransactionBody.with { proto in
            proto.topicID = TestConstants.topicId.toProtobuf()
            proto.message = Self.testMessageBytes
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.consensusSubmitMessage = protoData
            proto.transactionID = TestConstants.transactionId.toProtobuf()
        }

        let tx = try TopicMessageSubmitTransaction(protobuf: protoBody, [protoData])

        XCTAssertEqual(tx.topicId, TestConstants.topicId)
    }

    internal func test_GetSetTopicId() {
        let tx = TopicMessageSubmitTransaction()
        tx.topicId(TestConstants.topicId)

        XCTAssertEqual(tx.topicId, TestConstants.topicId)
    }

    internal func test_GetSetMessage() {
        let tx = TopicMessageSubmitTransaction()
        tx.message(Self.testMessageBytes)

        XCTAssertEqual(tx.message, Self.testMessageBytes)
    }

    internal func test_SetCustomFeeLimits() throws {
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

    internal func test_AddCustomFeeLimitToList() throws {
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

    internal func test_AddCustomFeeLimitToEmptyList() throws {
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

    internal func test_ScheduledCustomFeeLimits() throws {
        let payerId = AccountId(3)
        let amount: UInt64 = 4
        let tokenId = TokenId(3)
        let customFeeLimitToAdd = CustomFeeLimit(
            payerId: payerId,
            customFees: [
                CustomFixedFee(amount, nil, tokenId)
            ])

        let tx = TopicMessageSubmitTransaction()
            .addCustomFeeLimit(customFeeLimitToAdd)
            .schedule()
            .toProtobuf()

        XCTAssertEqual(tx.scheduledTransactionBody.maxCustomFees.count, 1)
        XCTAssertEqual(tx.scheduledTransactionBody.maxCustomFees[0].accountID.accountNum, Int64(payerId.num))
        XCTAssertEqual(tx.scheduledTransactionBody.maxCustomFees[0].fees.count, 1)
        XCTAssertEqual(tx.scheduledTransactionBody.maxCustomFees[0].fees[0].amount, Int64(amount))
        XCTAssertEqual(
            tx.scheduledTransactionBody.maxCustomFees[0].fees[0].denominatingTokenID.tokenNum, Int64(tokenId.num))

    }
}
