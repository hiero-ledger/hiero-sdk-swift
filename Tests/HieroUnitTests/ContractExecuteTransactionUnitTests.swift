// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class ContractExecuteTransactionUnitTests: HieroUnitTestCase, TransactionTestable {
    typealias TransactionType = ContractExecuteTransaction

    private static let contractId: ContractId = "0.0.5007"
    private static let gas: UInt64 = 10
    private static let payableAmount = Hbar.fromTinybars(1000)
    private static let functionParameters = Data([24, 43, 11])

    static func makeTransaction() throws -> ContractExecuteTransaction {
        try ContractExecuteTransaction()
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .sign(TestConstants.privateKey)
            .contractId(contractId)
            .gas(gas)
            .payableAmount(payableAmount)
            .functionParameters(functionParameters)
            .maxTransactionFee(Hbar.fromTinybars(100_000))
            .freeze()
    }

    internal func test_Serialize() throws {
        try assertTransactionSerializes()
    }

    internal func test_ToFromBytes() throws {
        try assertTransactionRoundTrips()
    }

    internal func test_FromProtoBody() throws {
        let protoData = Proto_ContractCallTransactionBody.with { proto in
            proto.contractID = Self.contractId.toProtobuf()
            proto.gas = Int64(Self.gas)
            proto.amount = Self.payableAmount.toTinybars()
            proto.functionParameters = Self.functionParameters
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.contractCall = protoData
            proto.transactionID = TestConstants.transactionId.toProtobuf()
        }

        let tx = try ContractExecuteTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.contractId, Self.contractId)
        XCTAssertEqual(tx.gas, Self.gas)
        XCTAssertEqual(tx.payableAmount, Self.payableAmount)
        XCTAssertEqual(tx.functionParameters, Self.functionParameters)
    }

    internal func test_GetSetContractId() {
        let tx = ContractExecuteTransaction()
        tx.contractId(Self.contractId)

        XCTAssertEqual(tx.contractId, Self.contractId)
    }

    internal func test_GetSetGas() {
        let tx = ContractExecuteTransaction()
        tx.gas(Self.gas)

        XCTAssertEqual(tx.gas, Self.gas)
    }

    internal func test_GetSetPayableAmount() {
        let tx = ContractExecuteTransaction()
        tx.payableAmount(Self.payableAmount)

        XCTAssertEqual(tx.payableAmount, Self.payableAmount)
    }

    internal func test_GetSetFunctionParameters() {
        let tx = ContractExecuteTransaction()
        tx.functionParameters(Self.functionParameters)

        XCTAssertEqual(tx.functionParameters, Self.functionParameters)
    }
}
