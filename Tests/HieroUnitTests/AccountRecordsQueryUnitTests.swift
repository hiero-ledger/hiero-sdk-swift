// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal class AccountRecordsQueryUnitTests: HieroUnitTestCase, QueryTestable {
    static func makeQueryProto() -> Proto_Query {
        AccountRecordsQuery(accountId: AccountId(num: 5005)).toQueryProtobufWith(.init())
    }

    internal func test_Serialize() throws {
        try assertQuerySerializes()
    }

    internal func test_GetSetAccountId() {
        let query = AccountRecordsQuery()
        query.accountId(5005)

        XCTAssertEqual(query.accountId, 5005)
    }
}
