// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class ScheduleInfoQueryUnitTests: HieroUnitTestCase, QueryTestable {
    static func makeQueryProto() throws -> Proto_Query {
        try ScheduleInfoQuery()
            .scheduleId(ScheduleId.fromString("0.0.5005"))
            .toQueryProtobufWith(.init())
    }

    internal func test_Serialize() throws {
        try assertQuerySerializes()
    }

    internal func test_GetSetScheduleId() throws {
        let query = ScheduleInfoQuery()
        query.scheduleId(TestConstants.scheduleId)

        XCTAssertEqual(query.scheduleId, TestConstants.scheduleId)
    }
}
