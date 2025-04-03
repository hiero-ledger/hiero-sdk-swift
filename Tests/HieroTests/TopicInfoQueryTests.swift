// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class TopicInfoQueryTests: XCTestCase {
    internal func testSerialize() {
        let query = TopicInfoQuery()
            .topicId("4.2.0")
            .toQueryProtobufWith(.init())

        assertSnapshot(matching: query, as: .description)
    }

    internal func testGetSettopicId() {
        let query = TopicInfoQuery()

        query.topicId("4.2.0")

        XCTAssertEqual(query.topicId, "4.2.0")
    }
}
