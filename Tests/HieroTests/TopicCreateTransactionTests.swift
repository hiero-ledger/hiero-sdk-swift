// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class TopicCreateTransactionTests: XCTestCase {
    private static let testAutoRenewAccountId: AccountId = "0.0.5007"
    private static let testAutoRenewPeriod: Duration = .days(1)

    private static func makeTransaction() throws -> TopicCreateTransaction {
        try TopicCreateTransaction()
            .nodeAccountIds(Resources.nodeAccountIds)
            .transactionId(Resources.txId)
            .sign(Resources.privateKey)
            .submitKey(.single(Resources.publicKey))
            .adminKey(.single(Resources.publicKey))
            .autoRenewAccountId(testAutoRenewAccountId)
            .autoRenewPeriod(testAutoRenewPeriod)
            .freeze()
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
        let protoData = Proto_ConsensusCreateTopicTransactionBody.with { proto in
            proto.submitKey = Resources.publicKey.toProtobuf()
            proto.adminKey = Resources.publicKey.toProtobuf()
            proto.autoRenewAccount = Self.testAutoRenewAccountId.toProtobuf()
            proto.autoRenewPeriod = Self.testAutoRenewPeriod.toProtobuf()
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.consensusCreateTopic = protoData
            proto.transactionID = Resources.txId.toProtobuf()
        }

        let tx = try TopicCreateTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.submitKey, .single(Resources.publicKey))
        XCTAssertEqual(tx.adminKey, .single(Resources.publicKey))
        XCTAssertEqual(tx.autoRenewAccountId, Self.testAutoRenewAccountId)
        XCTAssertEqual(tx.autoRenewPeriod, Self.testAutoRenewPeriod)
    }

    internal func testGetSetSubmitKey() {
        let tx = TopicCreateTransaction()
        tx.submitKey(.single(Resources.publicKey))

        XCTAssertEqual(tx.submitKey, .single(Resources.publicKey))
    }

    internal func testGetSetAdminKey() {
        let tx = TopicCreateTransaction()
        tx.adminKey(.single(Resources.publicKey))

        XCTAssertEqual(tx.adminKey, .single(Resources.publicKey))
    }

    internal func testGetSetAutoRenewAccountId() {
        let tx = TopicCreateTransaction()
        tx.autoRenewAccountId(Self.testAutoRenewAccountId)

        XCTAssertEqual(tx.autoRenewAccountId, Self.testAutoRenewAccountId)
    }

    internal func testGetSetAutoRenewPeriod() {
        let tx = TopicCreateTransaction()
        tx.autoRenewPeriod(Self.testAutoRenewPeriod)

        XCTAssertEqual(tx.autoRenewPeriod, Self.testAutoRenewPeriod)
    }

    internal func testAutomaticallySetAutoRenewAccountId() throws {
        let tx = TopicCreateTransaction()
        tx.transactionId(Resources.txId)
        try tx.freezeWith(nil)

        XCTAssertEqual(tx.autoRenewAccountId, Resources.txId.accountId)
    }
}
