// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class TokenNftInfoQueryUnitTests: HieroUnitTestCase, QueryTestable {
    static func makeQueryProto() -> Proto_Query {
        TokenNftInfoQuery()
            .nftId("0.0.5005@101")
            .toQueryProtobufWith(.init())
    }

    internal func test_Serialize() throws {
        try assertQuerySerializes()
    }

    internal func test_Properties() {
        let query = TokenNftInfoQuery()
        query
            .nftId(TokenId(num: 5005).nft(101))
            .maxPaymentAmount(Hbar.fromTinybars(100_000))

        XCTAssertEqual(query.nftId, "0.0.5005/101")
    }
}
