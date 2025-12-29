// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class DurationUnitTests: HieroUnitTestCase {
    private static let seconds: UInt64 = 1_554_158_542
    internal func test_Seconds() throws {
        let duration = Duration(seconds: Self.seconds)

        XCTAssertEqual(duration.seconds, Self.seconds)
    }

    internal func test_Minutes() throws {
        let duration = Duration.minutes(Self.seconds)

        XCTAssertEqual(duration.seconds, Self.seconds * 60)
    }

    internal func test_Hours() throws {
        let duration = Duration.hours(Self.seconds)

        XCTAssertEqual(duration.seconds, Self.seconds * 60 * 60)
    }

    internal func test_Days() throws {
        let duration = Duration.days(Self.seconds)

        XCTAssertEqual(duration.seconds, Self.seconds * 60 * 60 * 24)
    }

    internal func test_ToFromProtobuf() throws {
        let durationProto = Duration(seconds: Self.seconds).toProtobuf()

        let duration = Duration.fromProtobuf(durationProto)

        SnapshotTesting.assertSnapshot(of: duration, as: .description)
    }
}
