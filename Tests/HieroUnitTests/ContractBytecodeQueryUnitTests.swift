// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal class ContractBytecodeQueryUnitTests: HieroUnitTestCase, QueryTestable {
    static func makeQueryProto() -> Proto_Query {
        ContractBytecodeQuery(contractId: ContractId(num: 5005)).toQueryProtobufWith(.init())
    }

    internal func test_Serialize() throws {
        try assertQuerySerializes()
    }

    internal func test_GetSetContractId() {
        let query = ContractBytecodeQuery()
        query.contractId(5005)

        XCTAssertEqual(query.contractId, 5005)
    }
}
