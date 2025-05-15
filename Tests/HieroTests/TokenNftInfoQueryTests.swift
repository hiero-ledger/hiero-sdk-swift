// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class TokenNftInfoQueryTests: XCTestCase {
    internal func testSerialize() {
        let query = TokenNftInfoQuery()
            .nftId("0.0.5005@101")
            .toQueryProtobufWith(.init())

        assertSnapshot(matching: query, as: .description)
    }

    internal func testProperties() {
        let query = TokenNftInfoQuery()
        query
            .nftId(TokenId(num: 5005).nft(101))
            .maxPaymentAmount(Hbar.fromTinybars(100_000))

        XCTAssertEqual(query.nftId, "0.0.5005/101")
    }
}
