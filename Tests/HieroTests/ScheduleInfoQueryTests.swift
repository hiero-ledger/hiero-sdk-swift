// SPDX-License-Identifier: Apache-2.0

import SnapshotTesting
import XCTest

@testable import Hiero

internal final class ScheduleInfoQueryTests: XCTestCase {
    internal func testSerialize() throws {
        let query = try ScheduleInfoQuery()
            .scheduleId(ScheduleId.fromString("0.0.5005"))
            .toQueryProtobufWith(.init())

        assertSnapshot(of: query, as: .description)
    }

    internal func testGetSetScheduleId() throws {
        let query = ScheduleInfoQuery()
        query.scheduleId(Resources.scheduleId)

        XCTAssertEqual(query.scheduleId, Resources.scheduleId)
    }
}
