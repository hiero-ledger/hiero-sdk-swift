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

internal final class TopicMessageQueryTests: XCTestCase {
    internal func testGetSetTopicId() throws {
        let query = TopicMessageQuery()
        query.topicId(Resources.topicId)

        XCTAssertEqual(query.topicId, Resources.topicId)
    }

    internal func testGetSetStartTime() throws {
        let query = TopicMessageQuery()
        query.startTime(Resources.validStart)

        XCTAssertEqual(query.startTime, Resources.validStart)
    }

    internal func testGetSetEndTime() throws {
        let query = TopicMessageQuery()
        query.endTime(Resources.validStart)

        XCTAssertEqual(query.endTime, Resources.validStart)
    }

    internal func testGetSetLimit() throws {
        let query = TopicMessageQuery()
        query.limit(1415)

        XCTAssertEqual(query.limit, 1415)
    }
}
