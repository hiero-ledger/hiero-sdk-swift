// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal class ContractCallQueryTests: XCTestCase {
    private static let parameters: ContractFunctionParameters = ContractFunctionParameters().addString("hello")
        .addString("world!")

    private static func makeQuery() -> ContractCallQuery {
        ContractCallQuery(contractId: 5005, gas: 1541, senderAccountId: "1.2.3").maxPaymentAmount(100_000)
    }

    internal func testSerialize() throws {
        let query = Self.makeQuery().toQueryProtobufWith(.init())

        assertSnapshot(matching: query, as: .description)
    }

    internal func testFunctionParameters() throws {
        let query = Self.makeQuery()
            .functionParameters(Self.parameters.toBytes())
            .toQueryProtobufWith(.init())

        assertSnapshot(matching: query, as: .description)
    }

    internal func testGetSetContractId() {
        let query = ContractCallQuery()
        query.contractId(5005)

        XCTAssertEqual(query.contractId, 5005)
    }

    internal func testGetSetGas() {
        let query = ContractCallQuery()
        query.gas(1541)

        XCTAssertEqual(query.gas, 1541)
    }

    internal func testGetSetCallParameters() {
        let query = ContractCallQuery()
        query.functionParameters(Self.parameters.toBytes())

        XCTAssertEqual(query.functionParameters, Self.parameters.toBytes())
    }

    internal func testGetSetSenderAccountId() {
        let query = ContractCallQuery()
        query.senderAccountId("1.2.3")

        XCTAssertEqual(query.senderAccountId, "1.2.3")
    }
}
