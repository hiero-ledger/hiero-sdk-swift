// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class TopicInfoQueryUnitTests: HieroUnitTestCase, QueryTestable {
    static func makeQueryProto() -> Proto_Query {
        TopicInfoQuery()
            .topicId("4.2.0")
            .toQueryProtobufWith(.init())
    }

    internal func test_Serialize() throws {
        try assertQuerySerializes()
    }

    internal func test_GetSettopicId() {
        let query = TopicInfoQuery()

        query.topicId("4.2.0")

        XCTAssertEqual(query.topicId, "4.2.0")
    }
}
