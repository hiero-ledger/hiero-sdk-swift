// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class ContractInfoQueryUnitTests: HieroUnitTestCase, QueryTestable {
    static func makeQueryProto() throws -> Proto_Query {
        try ContractInfoQuery()
            .contractId(ContractId.fromString("0.0.5005"))
            .toQueryProtobufWith(.init())
    }

    internal func test_Serialize() throws {
        try assertQuerySerializes()
    }

    internal func test_GetSetContractId() {
        let query = ContractInfoQuery()
        query.contractId(5005)

        XCTAssertEqual(query.contractId, 5005)
    }
}
