// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class EthereumTransactionTests: XCTestCase {
    private static let ethereumData = "livestock".data(using: .utf8)!
    private static let callDataFileId: FileId = "4.5.6"
    private static let maxGasAllowanceHbar: Hbar = 3

    private static func createTransaction() throws -> EthereumTransaction {
        try EthereumTransaction()
            .nodeAccountIds(Resources.nodeAccountIds)
            .transactionId(Resources.txId)
            .sign(Resources.privateKey)
            .ethereumData(ethereumData)
            .callDataFileId(callDataFileId)
            .maxGasAllowanceHbar(maxGasAllowanceHbar)
            .maxTransactionFee(Hbar(1))
            .freeze()
    }

    internal func testSerialize() throws {
        assertSnapshot(of: try Self.createTransaction().makeProtoBody(), as: .description)
    }

    internal func testToFromBytes() throws {
        let tx = try Self.createTransaction()
        let tx2 = try Transaction.fromBytes(tx.toBytes())

        XCTAssertEqual(try tx.makeProtoBody(), try tx2.makeProtoBody())
    }

    internal func testFromProtoBody() throws {
        let protoData = Proto_EthereumTransactionBody.with { proto in
            proto.ethereumData = Self.ethereumData
            proto.callData = Self.callDataFileId.toProtobuf()
            proto.maxGasAllowance = Self.maxGasAllowanceHbar.tinybars
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.ethereumTransaction = protoData
            proto.transactionID = Resources.txId.toProtobuf()
        }

        let tx = try EthereumTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.ethereumData, Self.ethereumData)
        XCTAssertEqual(tx.callDataFileId, Self.callDataFileId)
        XCTAssertEqual(tx.maxGasAllowanceHbar, Self.maxGasAllowanceHbar)
    }

    internal func testGetSetEthereumData() {
        let tx = EthereumTransaction()
        tx.ethereumData(Self.ethereumData)

        XCTAssertEqual(tx.ethereumData, Self.ethereumData)
    }
    internal func testGetSetCallDataFileId() {
        let tx = EthereumTransaction()
        tx.callDataFileId(Self.callDataFileId)

        XCTAssertEqual(tx.callDataFileId, Self.callDataFileId)
    }
    internal func testGetSetMaxGasAllowanceHbar() {
        let tx = EthereumTransaction()
        tx.maxGasAllowanceHbar(Self.maxGasAllowanceHbar)

        XCTAssertEqual(tx.maxGasAllowanceHbar, Self.maxGasAllowanceHbar)
    }
}
