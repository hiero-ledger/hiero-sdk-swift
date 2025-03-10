// SPDX-License-Identifier: Apache-2.0

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
