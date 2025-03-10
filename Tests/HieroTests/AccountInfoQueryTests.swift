// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal class AccountInfoQueryTests: XCTestCase {
    internal func testSerialize() throws {
        let query = AccountInfoQuery(accountId: AccountId(num: 5005))
            .toQueryProtobufWith(.init())

        assertSnapshot(matching: query, as: .description)
    }

    internal func testGetSetAccountId() {
        let query = AccountInfoQuery()
        query.accountId(5005)

        XCTAssertEqual(query.accountId, 5005)
    }
}
