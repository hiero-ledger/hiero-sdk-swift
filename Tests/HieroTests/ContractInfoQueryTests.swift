// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class ContractInfoQueryTests: XCTestCase {
    internal func testSerialize() throws {
        let query = try ContractInfoQuery()
            .contractId(ContractId.fromString("0.0.5005"))
            .toQueryProtobufWith(.init())

        assertSnapshot(of: query, as: .description)
    }

    internal func testGetSetContractId() {
        let query = ContractInfoQuery()
        query.contractId(5005)

        XCTAssertEqual(query.contractId, 5005)
    }
}
