// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class FileIdTests: XCTestCase {
    internal func testFromString() {
        XCTAssertEqual(try FileId.fromString("0.0.5005"), FileId(num: 5005))
    }

    internal func testToFromBytes() {
        let a: FileId = "0.0.5005"
        XCTAssertEqual(a, try FileId.fromBytes(a.toBytes()))
        let b: FileId = "1.2.5005"
        XCTAssertEqual(b, try FileId.fromBytes(b.toBytes()))
    }

    internal func testFromSolidarityAddress() {
        assertSnapshot(
            matching: try FileId.fromSolidityAddress("000000000000000000000000000000000000138D"), as: .description)
    }

    internal func testToSolidityAddress() {
        assertSnapshot(matching: try FileId(5005).toSolidityAddress(), as: .lines)
    }
}
