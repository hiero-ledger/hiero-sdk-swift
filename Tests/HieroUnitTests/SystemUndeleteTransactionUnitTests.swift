// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class SystemUndeleteTransactionUnitTests: HieroUnitTestCase {
    private static let contractId: ContractId = 444
    private static let fileId: FileId = 444

    internal static func makeTransactionFile() throws -> SystemUndeleteTransaction {
        try SystemUndeleteTransaction()
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .sign(TestConstants.privateKey)
            .fileId(fileId)
            .freeze()
    }

    internal static func makeTransactionContract() throws -> SystemUndeleteTransaction {
        try SystemUndeleteTransaction()
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .sign(TestConstants.privateKey)
            .contractId(contractId)
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
        let protoData = Proto_SystemUndeleteTransactionBody.with { proto in
            proto.fileID = Self.fileId.toProtobuf()
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.systemUndelete = protoData
            proto.transactionID = TestConstants.transactionId.toProtobuf()
        }

        let tx = try SystemUndeleteTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.fileId, Self.fileId)
        XCTAssertEqual(tx.contractId, nil)
    }

    internal func test_GetSetFileId() {
        let tx = SystemUndeleteTransaction()
        tx.fileId(Self.fileId)

        XCTAssertEqual(tx.fileId, Self.fileId)
    }

    internal func test_GetSetContractId() throws {
        let tx = SystemUndeleteTransaction()
        tx.contractId(Self.contractId)

        XCTAssertEqual(tx.contractId, Self.contractId)
    }
}
