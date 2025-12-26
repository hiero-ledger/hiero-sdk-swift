// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import SnapshotTesting
import XCTest

@testable import Hiero

internal class ContractCallQueryUnitTests: HieroUnitTestCase, QueryTestable {
    private static let parameters: ContractFunctionParameters = ContractFunctionParameters().addString("hello")
        .addString("world!")

    private static func makeQuery() -> ContractCallQuery {
        ContractCallQuery(contractId: 5005, gas: 1541, senderAccountId: "1.2.3").maxPaymentAmount(100_000)
    }

    static func makeQueryProto() -> Proto_Query {
        makeQuery().toQueryProtobufWith(.init())
    }

    internal func test_Serialize() throws {
        try assertQuerySerializes()
    }

    internal func test_FunctionParameters() throws {
        let query = Self.makeQuery()
            .functionParameters(Self.parameters.toBytes())
            .toQueryProtobufWith(.init())

        SnapshotTesting.assertSnapshot(of: query, as: .description)
    }

    internal func test_GetSetContractId() {
        let query = ContractCallQuery()
        query.contractId(5005)

        XCTAssertEqual(query.contractId, 5005)
    }

    internal func test_GetSetGas() {
        let query = ContractCallQuery()
        query.gas(1541)

        XCTAssertEqual(query.gas, 1541)
    }

    internal func test_GetSetCallParameters() {
        let query = ContractCallQuery()
        query.functionParameters(Self.parameters.toBytes())

        XCTAssertEqual(query.functionParameters, Self.parameters.toBytes())
    }

    internal func test_GetSetSenderAccountId() {
        let query = ContractCallQuery()
        query.senderAccountId("1.2.3")

        XCTAssertEqual(query.senderAccountId, "1.2.3")
    }
}
