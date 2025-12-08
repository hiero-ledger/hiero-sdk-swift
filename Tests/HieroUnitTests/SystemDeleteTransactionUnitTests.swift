// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class SystemDeleteTransactionUnitTests: HieroUnitTestCase {
    private static let contractId: ContractId = 444
    private static let fileId: FileId = 444
    private static let expirationTime = TestConstants.validStart

    internal static func makeTransactionFile() throws -> SystemDeleteTransaction {
        try SystemDeleteTransaction()
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .sign(TestConstants.privateKey)
            .fileId(fileId)
            .expirationTime(expirationTime)
            .freeze()
    }

    internal static func makeTransactionContract() throws -> SystemDeleteTransaction {
        try SystemDeleteTransaction()
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .sign(TestConstants.privateKey)
            .contractId(444)
            .expirationTime(TestConstants.validStart)
            .freeze()
    }

    internal func test_SerializeFile() throws {
        let tx = try Self.makeTransactionFile().makeProtoBody()

        SnapshotTesting.assertSnapshot(of: tx, as: .description)
    }

    internal func test_ToFromBytesFile() throws {
        let tx = try Self.makeTransactionFile()

        let tx2 = try Transaction.fromBytes(tx.toBytes())

        XCTAssertEqual(try tx.makeProtoBody(), try tx2.makeProtoBody())
    }

    internal func test_SerializeContract() throws {
        let tx = try Self.makeTransactionContract().makeProtoBody()

        SnapshotTesting.assertSnapshot(of: tx, as: .description)
    }

    internal func test_ToFromBytesContract() throws {
        let tx = try Self.makeTransactionContract()

        let tx2 = try Transaction.fromBytes(tx.toBytes())

        XCTAssertEqual(try tx.makeProtoBody(), try tx2.makeProtoBody())
    }

    internal func test_FromProtoBody() throws {
        let protoData = Proto_SystemDeleteTransactionBody.with { proto in
            proto.fileID = Self.fileId.toProtobuf()
            proto.expirationTime = .with { $0.seconds = Self.expirationTime.toProtobuf().seconds }
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.systemDelete = protoData
            proto.transactionID = TestConstants.transactionId.toProtobuf()
        }

        let tx = try SystemDeleteTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.fileId, Self.fileId)
        XCTAssertEqual(tx.expirationTime, Self.expirationTime)
        XCTAssertEqual(tx.contractId, nil)
    }

    internal func test_GetSetFileId() {
        let tx = SystemDeleteTransaction()
        tx.fileId(Self.fileId)

        XCTAssertEqual(tx.fileId, Self.fileId)
    }

    internal func test_GetSetContractId() throws {
        let tx = SystemDeleteTransaction()
        tx.contractId(Self.contractId)

        XCTAssertEqual(tx.contractId, Self.contractId)
    }

    internal func test_GetSetExpirationTime() throws {
        let tx = SystemDeleteTransaction()
        tx.expirationTime(Self.expirationTime)

        XCTAssertEqual(tx.expirationTime, Self.expirationTime)
    }
}
