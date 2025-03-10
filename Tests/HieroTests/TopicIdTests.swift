// SPDX-License-Identifier: Apache-2.0

import SnapshotTesting
import XCTest

@testable import Hiero

internal final class TopicIdTests: XCTestCase {
    internal func testParse() {
        assertSnapshot(matching: try TopicId.fromString("0.0.5005"), as: .description)
    }

    internal func testFromSolidityAddress() {
        assertSnapshot(
            matching: try TopicId.fromSolidityAddress("000000000000000000000000000000000000138D"),
            as: .description
        )
    }

    internal func testFromSolidityAddress0x() {
        assertSnapshot(
            matching: try TopicId.fromSolidityAddress("0x000000000000000000000000000000000000138D"),
            as: .description
        )
    }

    internal func testToFromBytes() {
        let a: TopicId = "1.2.3"
        XCTAssertEqual(a, try .fromBytes(a.toBytes()))
    }

    internal func testToSolidityAddress() {
        assertSnapshot(matching: try TopicId(num: 5005).toSolidityAddress(), as: .lines)
    }
}
