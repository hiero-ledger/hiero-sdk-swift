// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class TokenInfoQueryUnitTests: HieroUnitTestCase, QueryTestable {
    static func makeQueryProto() -> Proto_Query {
        TokenInfoQuery()
            .tokenId("4.2.0")
            .toQueryProtobufWith(.init())
    }

    internal func test_Serialize() throws {
        try assertQuerySerializes()
    }

    internal func test_GetSetTokenId() {
        let query = TokenInfoQuery()

        query.tokenId("4.2.0")

        XCTAssertEqual(query.tokenId, "4.2.0")
    }
}
