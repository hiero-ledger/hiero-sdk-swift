// SPDX-License-Identifier: Apache-2.0

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
}
