// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class TopicUpdateTransactionTests: XCTestCase {
    private static let testTopicId: TopicId = 5007

    private static func makeTransaction() throws -> TopicUpdateTransaction {
        try TopicUpdateTransaction()
            .nodeAccountIds(Resources.nodeAccountIds)
            .transactionId(Resources.txId)
            .sign(Resources.privateKey)
            .topicId(testTopicId)
            .clearAdminKey()
            .clearAutoRenewAccountId()
            .clearSubmitKey()
            .topicMemo("")
            .freeze()
    }

    private static func makeTransaction2() throws -> TopicUpdateTransaction {
        try TopicUpdateTransaction()
            .nodeAccountIds(Resources.nodeAccountIds)
            .transactionId(Resources.txId)
            .sign(Resources.privateKey)
            .adminKey(.single(Resources.publicKey))
            .autoRenewAccountId(5009)
            .autoRenewPeriod(.days(1))
            .submitKey(.single(Resources.publicKey))
            .topicMemo("Hello memo")
            .expirationTime(Resources.validStart)
            .freeze()
    }

    internal func testSerialize() throws {
        let tx = try Self.makeTransaction().makeProtoBody()

        assertSnapshot(of: tx, as: .description)
    }

    internal func testToFromBytes() throws {
        let tx = try Self.makeTransaction()

        let tx2 = try Transaction.fromBytes(tx.toBytes())

        XCTAssertEqual(try tx.makeProtoBody(), try tx2.makeProtoBody())
    }

    internal func testSerialize2() throws {
        let tx = try Self.makeTransaction2().makeProtoBody()

        assertSnapshot(of: tx, as: .description)
    }

    internal func testToFromBytes2() throws {
        let tx = try Self.makeTransaction2()

        let tx2 = try Transaction.fromBytes(tx.toBytes())

        XCTAssertEqual(try tx.makeProtoBody(), try tx2.makeProtoBody())
    }

    internal func testFromProtoBody() throws {
        let protoData = Proto_ConsensusUpdateTopicTransactionBody.with { proto in
            proto.topicID = Self.testTopicId.toProtobuf()
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.consensusUpdateTopic = protoData
            proto.transactionID = Resources.txId.toProtobuf()
        }

        let tx = try TopicUpdateTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.topicId, Self.testTopicId)
    }

    internal func testGetSetTopicId() {
        let tx = TopicUpdateTransaction()
        tx.topicId(Self.testTopicId)

        XCTAssertEqual(tx.topicId, Self.testTopicId)
    }

    internal func testGetSetClearAdminKey() {
        let tx = TopicUpdateTransaction()
        tx.adminKey(.single(Resources.publicKey))

        XCTAssertEqual(tx.adminKey, .single(Resources.publicKey))

        tx.clearAdminKey()
        XCTAssertEqual(tx.adminKey, .keyList([]))
    }

    internal func testGetSetClearSubmitKey() {
        let tx = TopicUpdateTransaction()
        tx.submitKey(.single(Resources.publicKey))

        XCTAssertEqual(tx.submitKey, .single(Resources.publicKey))

        tx.clearSubmitKey()
        XCTAssertEqual(tx.submitKey, .keyList([]))
    }

    internal func testGetSetClearAutoRenewAccountId() {
        let tx = TopicUpdateTransaction()

        tx.autoRenewAccountId(5006)

        XCTAssertEqual(tx.autoRenewAccountId, 5006)

        tx.clearAutoRenewAccountId()
        XCTAssertEqual(tx.autoRenewAccountId, 0)
    }

    internal func testGetSetFeeScheduleKey() {
        let tx = TopicUpdateTransaction()
        tx.feeScheduleKey(.single(Resources.publicKey))

        XCTAssertEqual(tx.feeScheduleKey, .single(Resources.publicKey))
    }

    internal func testGetSetFeeExemptKeys() {
        let feeExemptKeys: [Key] = [
            .single(PrivateKey.generateEcdsa().publicKey), .single(PrivateKey.generateEcdsa().publicKey),
        ]
        let tx = TopicUpdateTransaction()
        tx.feeExemptKeys(feeExemptKeys)

        XCTAssertEqual(tx.feeExemptKeys, feeExemptKeys)
    }

    internal func testAddFeeExemptKeyToEmptyList() {
        let tx = TopicUpdateTransaction()

        let feeExemptKey: Key = .single(PrivateKey.generateEcdsa().publicKey)
        tx.feeExemptKeys([])
        tx.addFeeExemptKey(feeExemptKey)

        XCTAssertEqual(tx.feeExemptKeys, [feeExemptKey])
    }

    internal func testAddFeeExemptKeyToList() {
        let tx = TopicUpdateTransaction()

        let feeExemptKey: Key = .single(PrivateKey.generateEcdsa().publicKey)
        tx.feeExemptKeys([])
        tx.addFeeExemptKey(feeExemptKey)

        XCTAssertEqual(tx.feeExemptKeys, [feeExemptKey])
    }

    internal func testSetCustomFees() {
        let customFees: [CustomFixedFee] = [
            CustomFixedFee(1, nil, TokenId("0.0.1")),
            CustomFixedFee(2, nil, TokenId("0.0.2")),
            CustomFixedFee(3, nil, TokenId("0.0.3")),
        ]

        let tx = TopicUpdateTransaction()
        tx.customFees(customFees)

        XCTAssertEqual(tx.customFees, customFees)
    }

    internal func testAddCustomFeeToList() {
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

    internal func testClearCustomFees() {
        let tx = TopicUpdateTransaction()
        tx.customFees([CustomFixedFee(1, nil, TokenId("0.0.1"))])
        tx.clearCustomFees()

        XCTAssertEqual(tx.customFees, [])
    }
}
