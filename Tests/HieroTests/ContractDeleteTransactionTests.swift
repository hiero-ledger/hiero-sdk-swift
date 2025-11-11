// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal class ContractDeleteTransactionTests: XCTestCase {
    private static func makeTransaction() throws -> ContractDeleteTransaction {
        try ContractDeleteTransaction()
            .nodeAccountIds(Resources.nodeAccountIds)
            .transactionId(Resources.txId)
            .sign(Resources.privateKey)
            .contractId(5007)
            .transferAccountId("0.0.9")
            .transferContractId("0.0.5008")
            .maxTransactionFee(.fromTinybars(100_000))
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
        let protoData = Proto_ContractDeleteTransactionBody.with { proto in
            proto.contractID = ContractId(num: 5007).toProtobuf()
            proto.transferAccountID = AccountId(num: 9).toProtobuf()
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.contractDeleteInstance = protoData
            proto.transactionID = Resources.txId.toProtobuf()
        }

        let tx = try ContractDeleteTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.contractId, 5007)
        XCTAssertEqual(tx.transferAccountId, 9)
        XCTAssertEqual(tx.transferContractId, nil)
    }

    internal func testGetSetContractId() {
        let tx = ContractDeleteTransaction()
        tx.contractId(5007)

        XCTAssertEqual(tx.contractId, 5007)
    }
    internal func testGetSetTransferAccountId() {
        let tx = ContractDeleteTransaction()
        tx.transferAccountId(9)

        XCTAssertEqual(tx.transferAccountId, 9)
    }
    internal func testGetSetTransferContractId() {
        let tx = ContractDeleteTransaction()
        tx.transferContractId(5008)

        XCTAssertEqual(tx.transferContractId, 5008)
    }
}
