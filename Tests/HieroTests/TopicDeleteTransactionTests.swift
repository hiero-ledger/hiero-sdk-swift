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

internal final class TopicDeleteTransactionTests: XCTestCase {
    private static let testTopicId: TopicId = 5007

    private static func makeTransaction() throws -> TopicDeleteTransaction {
        try TopicDeleteTransaction()
            .nodeAccountIds(Resources.nodeAccountIds)
            .transactionId(Resources.txId)
            .sign(Resources.privateKey)
            .topicId(testTopicId)
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
        let protoData = Proto_ConsensusDeleteTopicTransactionBody.with { proto in
            proto.topicID = Self.testTopicId.toProtobuf()
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.consensusDeleteTopic = protoData
            proto.transactionID = Resources.txId.toProtobuf()
        }

        let tx = try TopicDeleteTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.topicId, Self.testTopicId)
    }

    internal func testGetSetTopicId() {
        let tx = TopicDeleteTransaction()
        tx.topicId(Self.testTopicId)

        XCTAssertEqual(tx.topicId, Self.testTopicId)
    }
}
