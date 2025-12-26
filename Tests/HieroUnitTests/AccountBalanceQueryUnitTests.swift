// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class AccountBalanceQueryUnitTests: HieroUnitTestCase, QueryTestable {
    static func makeQueryProto() -> Proto_Query {
        AccountBalanceQuery(accountId: 5005).toQueryProtobufWith(.init())
    }

    internal func test_SerializeWithAccountId() throws {
        try assertQuerySerializes()
    }

    internal func test_SerializeWithContractId() {
        let proto = AccountBalanceQuery(contractId: 5005).toQueryProtobufWith(.init())
        SnapshotTesting.assertSnapshot(of: proto, as: .description)
    }

    internal func test_GetSetAccountId() {
        let query = AccountBalanceQuery()
        query.accountId(5005)

        XCTAssertEqual(query.accountId, 5005)
    }

    internal func test_GetSetContractId() {
        let query = AccountBalanceQuery()
        query.contractId(1414)

        XCTAssertEqual(query.contractId, 1414)
    }
}
