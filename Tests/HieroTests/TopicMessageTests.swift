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

internal class TopicMessageTests: XCTestCase {
    private static let testSequenceNumber: UInt64 = 7

    private static let testContents = Data([0x01, 0x02, 0x03])
    private static let testRunningHash = Data([0x04, 0x05, 0x06])
    private static let testTxId = Resources.txId

    internal func testArguments() throws {
        let topicMessageChunk = TopicMessageChunk.init(
            header: ProtoTopicMessageHeader.init(
                consensusTimestamp: Resources.validStart, sequenceNumber: Self.testSequenceNumber,
                runningHash: Self.testRunningHash, runningHashVersion: 0, message: "yay".data(using: .utf8)!))

        let topicMessageChunkArr: [TopicMessageChunk] = [topicMessageChunk, topicMessageChunk, topicMessageChunk]

        let topicMessage = TopicMessage(
            consensusTimestamp: Resources.validStart, contents: Self.testContents, runningHash: Self.testRunningHash,
            runningHashVersion: 0, sequenceNumber: Self.testSequenceNumber, transaction: Self.testTxId,
            chunks: topicMessageChunkArr)

        XCTAssertEqual(topicMessage.consensusTimestamp, Resources.validStart)
        XCTAssertEqual(topicMessage.contents, Self.testContents)
        XCTAssertEqual(topicMessage.runningHash, Self.testRunningHash)
        XCTAssertEqual(topicMessage.sequenceNumber, Self.testSequenceNumber)
        XCTAssertEqual(topicMessage.chunks?.count, 3)
        XCTAssertEqual(topicMessage.transaction, Self.testTxId)
        XCTAssertEqual(topicMessage.runningHashVersion, 0)
    }

    internal func testSingle() throws {
        let topicMessageHeader = ProtoTopicMessageHeader.init(
            consensusTimestamp: Resources.validStart, sequenceNumber: Self.testSequenceNumber,
            runningHash: Self.testRunningHash, runningHashVersion: 0, message: Self.testContents)

        let topicMessage = TopicMessage(single: topicMessageHeader)

        XCTAssertEqual(topicMessage.consensusTimestamp, Resources.validStart)
        XCTAssertEqual(topicMessage.contents, Self.testContents)
        XCTAssertEqual(topicMessage.runningHash, Self.testRunningHash)
        XCTAssertEqual(topicMessage.sequenceNumber, Self.testSequenceNumber)
        XCTAssertEqual(topicMessage.chunks?.count, nil)
        XCTAssertEqual(topicMessage.transaction, nil)
    }

    internal func testMany() throws {
        let topicMessageChunk1 = ProtoTopicMessageChunk.init(
            header: ProtoTopicMessageHeader.init(
                consensusTimestamp: Resources.validStart, sequenceNumber: Self.testSequenceNumber,
                runningHash: Self.testRunningHash, runningHashVersion: 0, message: Self.testContents),
            initialTransactionId: Resources.txId, number: 1, total: 2)

        let topicMessageChunk2 = ProtoTopicMessageChunk.init(
            header: ProtoTopicMessageHeader.init(
                consensusTimestamp: Resources.validStart + Duration.seconds(1),
                sequenceNumber: Self.testSequenceNumber + 1,
                runningHash: Self.testRunningHash, runningHashVersion: 0, message: Self.testContents),
            initialTransactionId: Resources.txId, number: 2, total: 2)

        let topicMessage = TopicMessage.init(chunks: [topicMessageChunk1, topicMessageChunk2])

        XCTAssertEqual(topicMessage.consensusTimestamp, Resources.validStart + Duration.seconds(1))
        XCTAssertEqual(topicMessage.contents, Data([0x01, 0x02, 0x03, 0x01, 0x02, 0x03]))
        XCTAssertEqual(topicMessage.runningHash, Self.testRunningHash)
        XCTAssertEqual(topicMessage.sequenceNumber, Self.testSequenceNumber + 1)
        XCTAssertEqual(topicMessage.chunks?.count, 2)
        XCTAssertEqual(topicMessage.transaction, Resources.txId)
    }
}
