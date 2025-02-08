// SPDX-License-Identifier: Apache-2.0

import Hiero
import XCTest

internal class TopicCreate: XCTestCase {
    internal func testBasic() async throws {
        let testEnv = try TestEnvironment.nonFree

        let receipt = try await TopicCreateTransaction()
            .adminKey(.single(testEnv.operator.privateKey.publicKey))
            .topicMemo("[e2e::TopicCreateTransaction]")
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let topicId = try XCTUnwrap(receipt.topicId)

        let topic = Topic(id: topicId)

        try await topic.delete(testEnv)
    }

    internal func testFieldless() async throws {
        let testEnv = try TestEnvironment.nonFree

        let receipt = try await TopicCreateTransaction()
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try XCTUnwrap(receipt.topicId)
    }
}
