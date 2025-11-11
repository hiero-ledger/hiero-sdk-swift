// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal class ContractExecuteTransactionTests: XCTestCase {

    private static let contractId: ContractId = "0.0.5007"
    private static let gas: UInt64 = 10
    private static let payableAmount = Hbar.fromTinybars(1000)
    private static let functionParameters = Data([24, 43, 11])

    private static func makeTransaction() throws -> ContractExecuteTransaction {
        try ContractExecuteTransaction()
            .nodeAccountIds(Resources.nodeAccountIds)
            .transactionId(Resources.txId)
            .sign(Resources.privateKey)
            .contractId(contractId)
            .gas(gas)
            .payableAmount(payableAmount)
            .functionParameters(functionParameters)
            .maxTransactionFee(Hbar.fromTinybars(100_000))
            .freeze()
    }

    internal func testSerialize() throws {
        let tx = try Self.makeTransaction().makeProtoBody()

        assertSnapshot(of: tx, as: .description)
    }

    internal func testToFromBytes() throws {
        let tx = try Self.makeTransaction()
        let tx2 = try Transaction.fromBytes(tx.toBytes())

        XCTAssertEqual(try tx.makeProtoBody(), try tx2.makeProtoBody())
    }

    internal func testFromProtoBody() throws {
        let protoData = Proto_ContractCallTransactionBody.with { proto in
            proto.contractID = Self.contractId.toProtobuf()
            proto.gas = Int64(Self.gas)
            proto.amount = Self.payableAmount.toTinybars()
            proto.functionParameters = Self.functionParameters
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.contractCall = protoData
            proto.transactionID = Resources.txId.toProtobuf()
        }

        let tx = try ContractExecuteTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.contractId, Self.contractId)
        XCTAssertEqual(tx.gas, Self.gas)
        XCTAssertEqual(tx.payableAmount, Self.payableAmount)
        XCTAssertEqual(tx.functionParameters, Self.functionParameters)
    }

    internal func testGetSetContractId() {
        let tx = ContractExecuteTransaction()
        tx.contractId(Self.contractId)

        XCTAssertEqual(tx.contractId, Self.contractId)
    }

    internal func testGetSetGas() {
        let tx = ContractExecuteTransaction()
        tx.gas(Self.gas)

        XCTAssertEqual(tx.gas, Self.gas)
    }

    internal func testGetSetPayableAmount() {
        let tx = ContractExecuteTransaction()
        tx.payableAmount(Self.payableAmount)

        XCTAssertEqual(tx.payableAmount, Self.payableAmount)
    }

    internal func testGetSetFunctionParameters() {
        let tx = ContractExecuteTransaction()
        tx.functionParameters(Self.functionParameters)

        XCTAssertEqual(tx.functionParameters, Self.functionParameters)
    }
}
