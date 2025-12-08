// SPDX-License-Identifier: Apache-2.0

import GRPC
import Hiero
import HieroExampleUtilities
import HieroTestSupport
import XCTest

internal class TopicMessageQueryIntegrationTests: HieroIntegrationTestCase {
    internal func disabledTestBasic() async throws {
        // Given
        let topicId = try await createStandardTopic()

        // When
        async let submitFut = TopicMessageSubmitTransaction()
            .topicId(topicId)
            .message("Hello, from HCS!".data(using: .utf8)!)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        async let messages = withThrowingTaskGroup(of: [Hiero.TopicMessage].self) { group in
            group.addTask {
                for _ in 0..<20 {
                    do {
                        return try await TopicMessageQuery(
                            topicId: topicId,
                            startTime: .init(fromUnixTimestampNanos: 0),
                            limit: 1
                        )
                        .execute(self.testEnv.client)
                    } catch let error as HError {
                        // topic not found -> try again
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

        // Then
        do {
            let (messages, _) = try await (messages, submitFut)

            XCTAssertEqual(messages.count, 1)
            XCTAssertEqual(messages[0].contents, "Hello, from HCS!".data(using: .utf8)!)
        }
    }

    internal func disabledTestLarge() async throws {
        // Given
        let bigContents = Resources.bigContents.data(using: .utf8)!
        let topicId = try await createStandardTopic()

        // When
        async let submitFut = TopicMessageSubmitTransaction()
            .message(bigContents)
            .topicId(topicId)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        async let messages = withThrowingTaskGroup(of: [Hiero.TopicMessage].self) { group in
            group.addTask {
                for _ in 0..<20 {
                    do {
                        return try await TopicMessageQuery(
                            topicId: topicId,
                            startTime: .init(fromUnixTimestampNanos: 0),
                            limit: 14
                        )
                        .execute(self.testEnv.client)
                    } catch let error as HError {
                        // topic not found -> try again
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
                throw CancellationError()
            }

            defer { group.cancelAll() }
            return try await group.next()!
        }

        // Then
        do {
            let (messages, _) = try await (messages, submitFut)

            XCTAssertEqual(messages.count, 1)
            XCTAssertEqual(messages[0].contents, bigContents)
        }
    }
}
