/*
 * ‌
 * Hedera Swift SDK
 * ​
 * Copyright (C) 2023 - 2023 Hedera Hashgraph, LLC
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

        assertSnapshot(matching: duration, as: .description)
    }
}
