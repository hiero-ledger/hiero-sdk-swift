// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class TopicMessageQueryUnitTests: HieroUnitTestCase {
    internal func test_GetSetTopicId() throws {
        let query = TopicMessageQuery()
        query.topicId(TestConstants.topicId)

        XCTAssertEqual(query.topicId, TestConstants.topicId)
    }

    internal func test_GetSetStartTime() throws {
        let query = TopicMessageQuery()
        query.startTime(TestConstants.validStart)

        XCTAssertEqual(query.startTime, TestConstants.validStart)
    }

    internal func test_GetSetEndTime() throws {
        let query = TopicMessageQuery()
        query.endTime(TestConstants.validStart)

        XCTAssertEqual(query.endTime, TestConstants.validStart)
    }

    internal func test_GetSetLimit() throws {
        let query = TopicMessageQuery()
        query.limit(1415)

        XCTAssertEqual(query.limit, 1415)
    }
}
