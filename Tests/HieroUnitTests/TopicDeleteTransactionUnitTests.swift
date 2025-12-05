// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class TopicDeleteTransactionUnitTests: HieroUnitTestCase, TransactionTestable {
    typealias TransactionType = TopicDeleteTransaction

    private static let testTopicId: TopicId = 5007

    static func makeTransaction() throws -> TopicDeleteTransaction {
        try TopicDeleteTransaction()
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .sign(TestConstants.privateKey)
            .topicId(testTopicId)
            .freeze()
    }

    internal func test_Serialize() throws {
        try assertTransactionSerializes()
    }

    internal func test_ToFromBytes() throws {
        try assertTransactionRoundTrips()
    }

    internal func test_FromProtoBody() throws {
        let protoData = Proto_ConsensusDeleteTopicTransactionBody.with { proto in
            proto.topicID = Self.testTopicId.toProtobuf()
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.consensusDeleteTopic = protoData
            proto.transactionID = TestConstants.transactionId.toProtobuf()
        }

        let tx = try TopicDeleteTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.topicId, Self.testTopicId)
    }

    internal func test_GetSetTopicId() {
        let tx = TopicDeleteTransaction()
        tx.topicId(Self.testTopicId)

        XCTAssertEqual(tx.topicId, Self.testTopicId)
    }
}
