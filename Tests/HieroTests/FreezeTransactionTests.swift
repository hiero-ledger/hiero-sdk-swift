// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class FreezeTransactionTests: XCTestCase {
    private static let fileId: FileId = "4.5.6"
    private static let fileHash = Data(hexEncoded: "1723904587120938954702349857")!

    private static func makeTransaction() throws -> FreezeTransaction {
        try FreezeTransaction()
            .nodeAccountIds(Resources.nodeAccountIds)
            .transactionId(Resources.txId)
            .sign(Resources.privateKey)
            .fileId(fileId)
            .fileHash(fileHash)
            .startTime(Resources.validStart)
            .freezeType(.freezeAbort)
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
        let protoData = Proto_FreezeTransactionBody.with { proto in
            proto.updateFile = Self.fileId.toProtobuf()
            proto.fileHash = Self.fileHash
            proto.startTime = Resources.validStart.toProtobuf()
            proto.freezeType = .freezeAbort
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.freeze = protoData
            proto.transactionID = Resources.txId.toProtobuf()
        }

        let tx = try FreezeTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.fileId, Self.fileId)
        XCTAssertEqual(tx.fileHash, Self.fileHash)
        XCTAssertEqual(tx.startTime, Resources.validStart)
        XCTAssertEqual(tx.freezeType, .freezeAbort)
    }

    internal func testGetSetFileId() {
        let tx = FreezeTransaction()
        tx.fileId(Self.fileId)

        XCTAssertEqual(tx.fileId, Self.fileId)
    }

    internal func testGetSetFileHash() {
        let tx = FreezeTransaction()
        tx.fileHash(Self.fileHash)

        XCTAssertEqual(tx.fileHash, Self.fileHash)
    }

    internal func testGetSetStartTime() {
        let tx = FreezeTransaction()
        tx.startTime(Resources.validStart)

        XCTAssertEqual(tx.startTime, Resources.validStart)
    }

    internal func testGetSetFreezeType() {
        let tx = FreezeTransaction()
        tx.freezeType(.freezeAbort)

        XCTAssertEqual(tx.freezeType, .freezeAbort)
    }
}
