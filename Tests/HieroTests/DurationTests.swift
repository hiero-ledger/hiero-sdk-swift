// SPDX-License-Identifier: Apache-2.0

import SnapshotTesting
import XCTest

@testable import Hiero

internal final class DurationTests: XCTestCase {
    private static let seconds: UInt64 = 1_554_158_542
    internal func testSeconds() throws {
        let duration = Duration(seconds: Self.seconds)

        XCTAssertEqual(duration.seconds, Self.seconds)
    }

    internal func testMinutes() throws {
        let duration = Duration.minutes(Self.seconds)

        XCTAssertEqual(duration.seconds, Self.seconds * 60)
    }

    internal func testHours() throws {
        let duration = Duration.hours(Self.seconds)

        XCTAssertEqual(duration.seconds, Self.seconds * 60 * 60)
    }

    internal func testDays() throws {
        let duration = Duration.days(Self.seconds)

        XCTAssertEqual(duration.seconds, Self.seconds * 60 * 60 * 24)
    }

    internal func testToFromProtobuf() throws {
        let durationProto = Duration(seconds: Self.seconds).toProtobuf()

        let duration = Duration.fromProtobuf(durationProto)

        assertSnapshot(of: duration, as: .description)
    }
}
