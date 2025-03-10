// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

// SPDX-License-Identifier: Apache-2.0

internal class ContractBytecodeQueryTests: XCTestCase {
    internal func testSerialize() throws {
        let query = ContractBytecodeQuery(contractId: ContractId(num: 5005))
            .toQueryProtobufWith(.init())

        assertSnapshot(matching: query, as: .description)
    }

    internal func testGetSetContractId() {
        let query = ContractBytecodeQuery()
        query.contractId(5005)

        XCTAssertEqual(query.contractId, 5005)
    }
}
