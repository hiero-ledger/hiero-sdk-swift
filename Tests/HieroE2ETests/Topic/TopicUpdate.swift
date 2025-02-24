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

import Hiero
import XCTest

internal class TopicUpdate: XCTestCase {
    internal func testBasic() async throws {
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
