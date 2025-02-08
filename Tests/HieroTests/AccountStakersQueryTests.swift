// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal class AccountStakersQueryTests: XCTestCase {
    internal func testSerialize() throws {
        let query = AccountStakersQuery(accountId: AccountId(num: 5005))
            .toQueryProtobufWith(.init())

        assertSnapshot(matching: query, as: .description)
    }

    internal func testGetSetAccountId() {
        let query = AccountStakersQuery()
        query.accountId(5005)

        XCTAssertEqual(query.accountId, 5005)
    }
}
