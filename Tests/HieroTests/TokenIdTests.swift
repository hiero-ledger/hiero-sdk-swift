// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class TokenIdTests: XCTestCase {
    internal func testFromString() {
        XCTAssertEqual(try TokenId.fromString("0.0.5005"), TokenId(num: 5005))
    }

    internal func testToFromBytes() {
        let a: TokenId = "0.0.5005"
        XCTAssertEqual(a, try TokenId.fromBytes(a.toBytes()))
        let b: TokenId = "1.2.5005"
        XCTAssertEqual(b, try TokenId.fromBytes(b.toBytes()))
    }

    internal func testFromSolidityAddress() {
        assertSnapshot(
            matching: try TokenId.fromSolidityAddress("000000000000000000000000000000000000138d"), as: .description)
    }

    internal func testToSolidityAddress() {
        assertSnapshot(matching: try TokenId(5005).toSolidityAddress(), as: .lines)
    }
}
