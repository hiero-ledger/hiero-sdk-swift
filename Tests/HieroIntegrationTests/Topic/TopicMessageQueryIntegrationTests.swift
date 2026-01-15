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
    /// so this method retries with exponential backoff on "not found" errors.
    /// A configurable timeout prevents the test from hanging indefinitely.
    ///
    /// - Parameters:
    ///   - topicId: The topic to query messages from
    ///   - limit: Maximum number of messages to retrieve
    ///   - timeoutSeconds: Maximum time to wait before failing (default: 120 for large messages)
    /// - Returns: Array of topic messages
    private func queryTopicMessagesWithRetry(
        topicId: TopicId,
        limit: UInt64,
        timeoutSeconds: UInt64 = 120
    ) async throws -> [TopicMessage] {
        try await withThrowingTaskGroup(of: [TopicMessage].self) { group in
            group.addTask {
                var attempt = 0
                let maxAttempts = 60  // More attempts with backoff

                while attempt < maxAttempts {
                    attempt += 1
                    do {
                        return try await TopicMessageQuery(
                            topicId: topicId,
                            startTime: .init(fromUnixTimestampNanos: 0),
                            limit: limit
                        )
                        .execute(self.testEnv.client)
                    } catch let error as HError {
                        // Topic not found or unavailable on mirror node yet -> retry
                        switch error.kind {
                        case .grpcStatus(let status)
                        where status == GRPCStatus.Code.notFound.rawValue
                            || status == GRPCStatus.Code.unavailable.rawValue:
                            // Exponential backoff: 500ms, 1s, 2s, capped at 3s
                            let delayMs = min(500 * (1 << min(attempt - 1, 3)), 3000)
                            try await Task.sleep(nanoseconds: UInt64(delayMs) * 1_000_000)
                            continue

                        default: throw error
                        }
                    }
                }

                XCTFail("Couldn't get topic after \(maxAttempts) attempts")
                throw CancellationError()
            }

            group.addTask {
                await Task.yield()
                try await Task.sleep(nanoseconds: timeoutSeconds * 1_000_000_000)
                XCTFail("Operation timed out after \(timeoutSeconds) seconds")
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

        // Give the mirror node time to index the message
        try await Task.sleep(nanoseconds: 2 * 1_000_000_000)

        // When
        let messages = try await queryTopicMessagesWithRetry(topicId: topicId, limit: 1, timeoutSeconds: 60)

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

        // Large messages are chunked and take longer for the mirror node to index and reassemble
        try await Task.sleep(nanoseconds: 5 * 1_000_000_000)

        // When - use longer timeout for large chunked messages
        let messages = try await queryTopicMessagesWithRetry(topicId: topicId, limit: 14, timeoutSeconds: 180)

        // Then
        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual(messages[0].contents, bigContents)
    }
}
