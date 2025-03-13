// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class SystemUndeleteTransactionTests: XCTestCase {
    private static let contractId: ContractId = 444
    private static let fileId: FileId = 444

    internal static func makeTransactionFile() throws -> SystemUndeleteTransaction {
        try SystemUndeleteTransaction()
            .nodeAccountIds(Resources.nodeAccountIds)
            .transactionId(Resources.txId)
            .sign(Resources.privateKey)
            .fileId(fileId)
            .freeze()
    }

    internal static func makeTransactionContract() throws -> SystemUndeleteTransaction {
        try SystemUndeleteTransaction()
            .nodeAccountIds(Resources.nodeAccountIds)
            .transactionId(Resources.txId)
            .sign(Resources.privateKey)
            .contractId(contractId)
            .freeze()
    }

    internal func testSerializeFile() throws {
        let tx = try Self.makeTransactionFile().makeProtoBody()

        assertSnapshot(matching: tx, as: .description)
    }

    internal func testToFromBytesFile() throws {
        let tx = try Self.makeTransactionFile()

        let tx2 = try Transaction.fromBytes(tx.toBytes())

        XCTAssertEqual(try tx.makeProtoBody(), try tx2.makeProtoBody())
    }

    internal func testSerializeContract() throws {
        let tx = try Self.makeTransactionContract().makeProtoBody()

        assertSnapshot(matching: tx, as: .description)
    }

    internal func testToFromBytesContract() throws {
        let tx = try Self.makeTransactionContract()

        let tx2 = try Transaction.fromBytes(tx.toBytes())

        XCTAssertEqual(try tx.makeProtoBody(), try tx2.makeProtoBody())
    }

    internal func testFromProtoBody() throws {
        let protoData = Proto_SystemUndeleteTransactionBody.with { proto in
            proto.fileID = Self.fileId.toProtobuf()
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.systemUndelete = protoData
            proto.transactionID = Resources.txId.toProtobuf()
        }

        let tx = try SystemUndeleteTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.fileId, Self.fileId)
        XCTAssertEqual(tx.contractId, nil)
    }

    internal func testGetSetFileId() {
        let tx = SystemUndeleteTransaction()
        tx.fileId(Self.fileId)

        XCTAssertEqual(tx.fileId, Self.fileId)
    }

    internal func testGetSetContractId() throws {
        let tx = SystemUndeleteTransaction()
        tx.contractId(Self.contractId)

        XCTAssertEqual(tx.contractId, Self.contractId)
    }
}
