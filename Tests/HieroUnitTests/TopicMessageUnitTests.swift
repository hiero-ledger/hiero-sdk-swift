// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import SnapshotTesting
import XCTest

@testable import Hiero

internal class TopicMessageUnitTests: HieroUnitTestCase {
    private static let testSequenceNumber: UInt64 = 7

    private static let testContents = Data([0x01, 0x02, 0x03])
    private static let testRunningHash = Data([0x04, 0x05, 0x06])
    private static let testTxId = TestConstants.transactionId

    internal func test_Arguments() throws {
        let topicMessageChunk = TopicMessageChunk.init(
            header: ProtoTopicMessageHeader.init(
                consensusTimestamp: TestConstants.validStart, sequenceNumber: Self.testSequenceNumber,
                runningHash: Self.testRunningHash, runningHashVersion: 0, message: "yay".data(using: .utf8)!))

        let topicMessageChunkArr: [TopicMessageChunk] = [topicMessageChunk, topicMessageChunk, topicMessageChunk]

        let topicMessage = TopicMessage(
            consensusTimestamp: TestConstants.validStart, contents: Self.testContents, runningHash: Self.testRunningHash,
            runningHashVersion: 0, sequenceNumber: Self.testSequenceNumber, transaction: Self.testTxId,
            chunks: topicMessageChunkArr)

        XCTAssertEqual(topicMessage.consensusTimestamp, TestConstants.validStart)
        XCTAssertEqual(topicMessage.contents, Self.testContents)
        XCTAssertEqual(topicMessage.runningHash, Self.testRunningHash)
        XCTAssertEqual(topicMessage.sequenceNumber, Self.testSequenceNumber)
        XCTAssertEqual(topicMessage.chunks?.count, 3)
        XCTAssertEqual(topicMessage.transaction, Self.testTxId)
        XCTAssertEqual(topicMessage.runningHashVersion, 0)
    }

    internal func test_Single() throws {
        let topicMessageHeader = ProtoTopicMessageHeader.init(
            consensusTimestamp: TestConstants.validStart, sequenceNumber: Self.testSequenceNumber,
            runningHash: Self.testRunningHash, runningHashVersion: 0, message: Self.testContents)

        let topicMessage = TopicMessage(single: topicMessageHeader)

        XCTAssertEqual(topicMessage.consensusTimestamp, TestConstants.validStart)
        XCTAssertEqual(topicMessage.contents, Self.testContents)
        XCTAssertEqual(topicMessage.runningHash, Self.testRunningHash)
        XCTAssertEqual(topicMessage.sequenceNumber, Self.testSequenceNumber)
        XCTAssertEqual(topicMessage.chunks?.count, nil)
        XCTAssertEqual(topicMessage.transaction, nil)
    }

    internal func test_Many() throws {
        let topicMessageChunk1 = ProtoTopicMessageChunk.init(
            header: ProtoTopicMessageHeader.init(
                consensusTimestamp: TestConstants.validStart, sequenceNumber: Self.testSequenceNumber,
                runningHash: Self.testRunningHash, runningHashVersion: 0, message: Self.testContents),
            initialTransactionId: TestConstants.transactionId, number: 1, total: 2)

        let topicMessageChunk2 = ProtoTopicMessageChunk.init(
            header: ProtoTopicMessageHeader.init(
                consensusTimestamp: TestConstants.validStart + Duration.seconds(1),
                sequenceNumber: Self.testSequenceNumber + 1,
                runningHash: Self.testRunningHash, runningHashVersion: 0, message: Self.testContents),
            initialTransactionId: TestConstants.transactionId, number: 2, total: 2)

        let topicMessage = TopicMessage.init(chunks: [topicMessageChunk1, topicMessageChunk2])

        XCTAssertEqual(topicMessage.consensusTimestamp, TestConstants.validStart + Duration.seconds(1))
        XCTAssertEqual(topicMessage.contents, Data([0x01, 0x02, 0x03, 0x01, 0x02, 0x03]))
        XCTAssertEqual(topicMessage.runningHash, Self.testRunningHash)
        XCTAssertEqual(topicMessage.sequenceNumber, Self.testSequenceNumber + 1)
        XCTAssertEqual(topicMessage.chunks?.count, 2)
        XCTAssertEqual(topicMessage.transaction, TestConstants.transactionId)
    }
}
