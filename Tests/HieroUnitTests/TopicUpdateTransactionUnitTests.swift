// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class TopicUpdateTransactionUnitTests: HieroUnitTestCase, TransactionTestable {
    typealias TransactionType = TopicUpdateTransaction

    private static let testTopicId: TopicId = 5007

    static func makeTransaction() throws -> TopicUpdateTransaction {
        try TopicUpdateTransaction()
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .sign(TestConstants.privateKey)
            .topicId(testTopicId)
            .clearAdminKey()
            .clearAutoRenewAccountId()
            .clearSubmitKey()
            .topicMemo("")
            .freeze()
    }

    private static func makeTransaction2() throws -> TopicUpdateTransaction {
        try TopicUpdateTransaction()
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .sign(TestConstants.privateKey)
            .adminKey(.single(TestConstants.publicKey))
            .autoRenewAccountId(5009)
            .autoRenewPeriod(.days(1))
            .submitKey(.single(TestConstants.publicKey))
            .topicMemo("Hello memo")
            .expirationTime(TestConstants.validStart)
            .freeze()
    }

    internal func test_Serialize() throws {
        try assertTransactionSerializes()
    }

    internal func test_ToFromBytes() throws {
        try assertTransactionRoundTrips()
    }

    internal func test_Serialize2() throws {
        let tx = try Self.makeTransaction2().makeProtoBody()

        SnapshotTesting.assertSnapshot(of: tx, as: .description)
    }

    internal func test_ToFromBytes2() throws {
        let tx = try Self.makeTransaction2()

        let tx2 = try Transaction.fromBytes(tx.toBytes())

        XCTAssertEqual(try tx.makeProtoBody(), try tx2.makeProtoBody())
    }

    internal func test_FromProtoBody() throws {
        let protoData = Proto_ConsensusUpdateTopicTransactionBody.with { proto in
            proto.topicID = Self.testTopicId.toProtobuf()
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.consensusUpdateTopic = protoData
            proto.transactionID = TestConstants.transactionId.toProtobuf()
        }

        let tx = try TopicUpdateTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.topicId, Self.testTopicId)
    }

    internal func test_GetSetTopicId() {
        let tx = TopicUpdateTransaction()
        tx.topicId(Self.testTopicId)

        XCTAssertEqual(tx.topicId, Self.testTopicId)
    }

    internal func test_GetSetClearAdminKey() {
        let tx = TopicUpdateTransaction()
        tx.adminKey(.single(TestConstants.publicKey))

        XCTAssertEqual(tx.adminKey, .single(TestConstants.publicKey))

        tx.clearAdminKey()
        XCTAssertEqual(tx.adminKey, .keyList([]))
    }

    internal func test_GetSetClearSubmitKey() {
        let tx = TopicUpdateTransaction()
        tx.submitKey(.single(TestConstants.publicKey))

        XCTAssertEqual(tx.submitKey, .single(TestConstants.publicKey))

        tx.clearSubmitKey()
        XCTAssertEqual(tx.submitKey, .keyList([]))
    }

    internal func test_GetSetClearAutoRenewAccountId() {
        let tx = TopicUpdateTransaction()

        tx.autoRenewAccountId(5006)

        XCTAssertEqual(tx.autoRenewAccountId, 5006)

        tx.clearAutoRenewAccountId()
        XCTAssertEqual(tx.autoRenewAccountId, 0)
    }

    internal func test_GetSetFeeScheduleKey() {
        let tx = TopicUpdateTransaction()
        tx.feeScheduleKey(.single(TestConstants.publicKey))

        XCTAssertEqual(tx.feeScheduleKey, .single(TestConstants.publicKey))
    }

    internal func test_GetSetFeeExemptKeys() {
        let feeExemptKeys: [Key] = [
            .single(PrivateKey.generateEcdsa().publicKey), .single(PrivateKey.generateEcdsa().publicKey),
        ]
        let tx = TopicUpdateTransaction()
        tx.feeExemptKeys(feeExemptKeys)

        XCTAssertEqual(tx.feeExemptKeys, feeExemptKeys)
    }

    internal func test_AddFeeExemptKeyToEmptyList() {
        let tx = TopicUpdateTransaction()

        let feeExemptKey: Key = .single(PrivateKey.generateEcdsa().publicKey)
        tx.feeExemptKeys([])
        tx.addFeeExemptKey(feeExemptKey)

        XCTAssertEqual(tx.feeExemptKeys, [feeExemptKey])
    }

    internal func test_AddFeeExemptKeyToList() {
        let tx = TopicUpdateTransaction()

        let feeExemptKey: Key = .single(PrivateKey.generateEcdsa().publicKey)
        tx.feeExemptKeys([])
        tx.addFeeExemptKey(feeExemptKey)

        XCTAssertEqual(tx.feeExemptKeys, [feeExemptKey])
    }

    internal func test_SetCustomFees() {
        let customFees: [CustomFixedFee] = [
            CustomFixedFee(1, nil, TokenId("0.0.1")),
            CustomFixedFee(2, nil, TokenId("0.0.2")),
            CustomFixedFee(3, nil, TokenId("0.0.3")),
        ]

        let tx = TopicUpdateTransaction()
        tx.customFees(customFees)

        XCTAssertEqual(tx.customFees, customFees)
    }

    internal func test_AddCustomFeeToList() {
        var customFees: [CustomFixedFee] = [
            CustomFixedFee(1, nil, TokenId("0.0.1")),
            CustomFixedFee(2, nil, TokenId("0.0.2")),
            CustomFixedFee(3, nil, TokenId("0.0.3")),
        ]

        let customFeeToAdd = CustomFixedFee(1, nil, TokenId("0.0.1"))

        let tx = TopicUpdateTransaction()
        tx.customFees(customFees)
        tx.addCustomFee(customFeeToAdd)

        customFees.append(customFeeToAdd)

        XCTAssertEqual(tx.customFees, customFees)
    }

    internal func test_ClearCustomFees() {
        let tx = TopicUpdateTransaction()
        tx.customFees([CustomFixedFee(1, nil, TokenId("0.0.1"))])
        tx.clearCustomFees()

        XCTAssertEqual(tx.customFees, [])
    }
}
