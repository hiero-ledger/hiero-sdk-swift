// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class TokenInfoQueryTests: XCTestCase {
    internal func testSerialize() {
        let query = TokenInfoQuery()
            .tokenId("4.2.0")
            .toQueryProtobufWith(.init())

        assertSnapshot(of: query, as: .description)
    }

    internal func testGetSetTokenId() {
        let query = TokenInfoQuery()

        query.tokenId("4.2.0")

        XCTAssertEqual(query.tokenId, "4.2.0")
    }
}
