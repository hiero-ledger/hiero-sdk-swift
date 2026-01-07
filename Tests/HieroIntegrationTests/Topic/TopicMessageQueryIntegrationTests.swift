// SPDX-License-Identifier: Apache-2.0

import GRPC
import Hiero
import HieroExampleUtilities
import HieroTestSupport
import XCTest

internal class TopicMessageQueryIntegrationTests: HieroIntegrationTestCase {
    /// Queries topic messages with retry logic and timeout protection.
    ///
    /// The mirror node may not immediately have the topic available after creation,
    /// so this method retries up to 20 times with 200ms delays on "not found" errors.
    /// A 60-second timeout prevents the test from hanging indefinitely.
    ///
    /// - Parameters:
    ///   - topicId: The topic to query messages from
    ///   - limit: Maximum number of messages to retrieve
    /// - Returns: Array of topic messages
    private func queryTopicMessagesWithRetry(topicId: TopicId, limit: UInt64) async throws -> [TopicMessage] {
        try await withThrowingTaskGroup(of: [TopicMessage].self) { group in
            group.addTask {
                for _ in 0..<20 {
                    do {
                        return try await TopicMessageQuery(
                            topicId: topicId,
                            startTime: .init(fromUnixTimestampNanos: 0),
                            limit: limit
                        )
                        .execute(self.testEnv.client)
                    } catch let error as HError {
                        // Topic not found on mirror node yet -> retry
                        switch error.kind {
                        case .grpcStatus(let status) where status == GRPCStatus.Code.notFound.rawValue:
                            try await Task.sleep(nanoseconds: 200 * 1_000_000)
                            continue

                        default: throw error
                        }
                    }
                }

                XCTFail("Couldn't get topic after 20 attempts")
                throw CancellationError()
            }

            group.addTask {
                await Task.yield()
                try await Task.sleep(nanoseconds: 60 * 1_000_000_000)
                XCTFail("Operation timed out")
                throw CancellationError()
            }

            defer { group.cancelAll() }
            return try await group.next()!
        }
    }

    internal func test_Basic() async throws {
        // Given
        let topicId = try await createStandardTopic()
        let messageContent = "Hello, from HCS!".data(using: .utf8)!

        _ = try await TopicMessageSubmitTransaction()
            .topicId(topicId)
            .message(messageContent)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // When
        let messages = try await queryTopicMessagesWithRetry(topicId: topicId, limit: 1)

        // Then
        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual(messages[0].contents, messageContent)
    }

    internal func test_Large() async throws {
        // Given
        let bigContents = Resources.bigContents.data(using: .utf8)!
        let topicId = try await createStandardTopic()

        _ = try await TopicMessageSubmitTransaction()
            .topicId(topicId)
            .message(bigContents)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // When
        let messages = try await queryTopicMessagesWithRetry(topicId: topicId, limit: 14)

        // Then
        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual(messages[0].contents, bigContents)
    }
}
