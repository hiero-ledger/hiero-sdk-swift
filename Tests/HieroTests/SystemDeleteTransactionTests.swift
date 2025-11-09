// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class SystemDeleteTransactionTests: XCTestCase {
    private static let contractId: ContractId = 444
    private static let fileId: FileId = 444
    private static let expirationTime = Resources.validStart

    internal static func makeTransactionFile() throws -> SystemDeleteTransaction {
        try SystemDeleteTransaction()
            .nodeAccountIds(Resources.nodeAccountIds)
            .transactionId(Resources.txId)
            .sign(Resources.privateKey)
            .fileId(fileId)
            .expirationTime(expirationTime)
            .freeze()
    }

    internal static func makeTransactionContract() throws -> SystemDeleteTransaction {
        try SystemDeleteTransaction()
            .nodeAccountIds(Resources.nodeAccountIds)
            .transactionId(Resources.txId)
            .sign(Resources.privateKey)
            .contractId(444)
            .expirationTime(Resources.validStart)
            .freeze()
    }

    internal func testSerializeFile() throws {
        let tx = try Self.makeTransactionFile().makeProtoBody()

        assertSnapshot(of: tx, as: .description)
    }

    internal func testToFromBytesFile() throws {
        let tx = try Self.makeTransactionFile()

        let tx2 = try Transaction.fromBytes(tx.toBytes())

        XCTAssertEqual(try tx.makeProtoBody(), try tx2.makeProtoBody())
    }

    internal func testSerializeContract() throws {
        let tx = try Self.makeTransactionContract().makeProtoBody()

        assertSnapshot(of: tx, as: .description)
    }

    internal func testToFromBytesContract() throws {
        let tx = try Self.makeTransactionContract()

        let tx2 = try Transaction.fromBytes(tx.toBytes())

        XCTAssertEqual(try tx.makeProtoBody(), try tx2.makeProtoBody())
    }

    internal func testFromProtoBody() throws {
        let protoData = Proto_SystemDeleteTransactionBody.with { proto in
            proto.fileID = Self.fileId.toProtobuf()
            proto.expirationTime = .with { $0.seconds = Self.expirationTime.toProtobuf().seconds }
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.systemDelete = protoData
            proto.transactionID = Resources.txId.toProtobuf()
        }

        let tx = try SystemDeleteTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.fileId, Self.fileId)
        XCTAssertEqual(tx.expirationTime, Self.expirationTime)
        XCTAssertEqual(tx.contractId, nil)
    }

    internal func testGetSetFileId() {
        let tx = SystemDeleteTransaction()
        tx.fileId(Self.fileId)

        XCTAssertEqual(tx.fileId, Self.fileId)
    }

    internal func testGetSetContractId() throws {
        let tx = SystemDeleteTransaction()
        tx.contractId(Self.contractId)

        XCTAssertEqual(tx.contractId, Self.contractId)
    }

    internal func testGetSetExpirationTime() throws {
        let tx = SystemDeleteTransaction()
        tx.expirationTime(Self.expirationTime)

        XCTAssertEqual(tx.expirationTime, Self.expirationTime)
    }
}
