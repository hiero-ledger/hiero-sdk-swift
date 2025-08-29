// SPDX-License-Identifier: Apache-2.0

import Hiero
import XCTest

internal class TopicUpdate: XCTestCase {
    internal func disabledTestBasic() async throws {
        let testEnv = try TestEnvironment.nonFree

        let topic = try await Topic.create(testEnv)

        addTeardownBlock {
            try await topic.delete(testEnv)
        }

        _ = try await TopicUpdateTransaction()
            .topicId(topic.id)
            .clearAutoRenewAccountId()
            .topicMemo("hello")
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let info = try await TopicInfoQuery(topicId: topic.id).execute(testEnv.client)

        XCTAssertEqual(info.topicMemo, "hello")
        XCTAssertEqual(info.autoRenewAccountId, nil)
    }
}
