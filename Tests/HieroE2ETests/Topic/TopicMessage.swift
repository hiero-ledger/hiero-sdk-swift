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

import GRPC
import Hiero
import HieroExampleUtilities
import XCTest

internal class TopicMessage: XCTestCase {
    internal func testBasic() async throws {
        let testEnv = try TestEnvironment.nonFree

        let topic = try await Topic.create(testEnv)

        addTeardownBlock {
            try await topic.delete(testEnv)
        }

        async let submitFut = TopicMessageSubmitTransaction()
            .topicId(topic.id)
            .message("Hello, from HCS!".data(using: .utf8)!)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        async let messages = withThrowingTaskGroup(of: [Hiero.TopicMessage].self) { group in
            group.addTask {
                for _ in 0..<20 {
                    do {
                        return try await TopicMessageQuery(
                            topicId: topic.id,
                            startTime: .init(fromUnixTimestampNanos: 0),
                            limit: 1
                        )
                        .execute(testEnv.client)
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

        do {
            let (messages, _) = try await (messages, submitFut)

            XCTAssertEqual(messages.count, 1)
            XCTAssertEqual(messages[0].contents, "Hello, from HCS!".data(using: .utf8)!)
        }
    }

    internal func testLarge() async throws {
        let testEnv = try TestEnvironment.nonFree
        async let bigContentsFut = Resources.bigContents.data(using: .utf8)!

        let topic = try await Topic.create(testEnv)

        addTeardownBlock {
            try await topic.delete(testEnv)
        }

        let bigContents = try await bigContentsFut

        async let submitFut = TopicMessageSubmitTransaction()
            .message(bigContents)
            .topicId(topic.id)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        async let messages = withThrowingTaskGroup(of: [Hiero.TopicMessage].self) { group in
            group.addTask {
                for _ in 0..<20 {
                    do {
                        return try await TopicMessageQuery(
                            topicId: topic.id,
                            startTime: .init(fromUnixTimestampNanos: 0),
                            limit: 14
                        )
                        .execute(testEnv.client)
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

        do {
            let (messages, _) = try await (messages, submitFut)

            XCTAssertEqual(messages.count, 1)
            XCTAssertEqual(messages[0].contents, bigContents)
        }
    }
}
