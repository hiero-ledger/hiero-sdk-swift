// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class FileUpdateTransactionTests: XCTestCase {
    private static let testMemo = "test Memo"
    private static let testContents: Data = "[swift::unit::fileUpdate::1]".data(using: .utf8)!

    private static func createTransaction() throws -> FileUpdateTransaction {
        try FileUpdateTransaction()
            .nodeAccountIds([AccountId("0.0.5005"), AccountId("0.0.5006")])
            .transactionId(
                TransactionId(
                    accountId: 5006, validStart: Timestamp(seconds: 1_554_158_542, subSecondNanos: 0), scheduled: false)
            )
            .fileId("1.2.4")
            .contents(Self.testContents)
            .expirationTime(Timestamp(seconds: 1_554_158_728, subSecondNanos: 0))
            .keys(.init(keys: [.single(Resources.publicKey)]))
            .maxTransactionFee(.fromTinybars(100_000))
            .fileMemo("Hello memo")
            .freeze()
            .sign(Resources.privateKey)
    }

    internal func testSerialize() throws {
        let tx = try Self.createTransaction().makeProtoBody()

        assertSnapshot(matching: tx, as: .description)
    }

    internal func testToFromBytes() throws {
        let tx = try Self.createTransaction()
        let tx2 = try Transaction.fromBytes(tx.toBytes())

        XCTAssertEqual(try tx.makeProtoBody(), try tx2.makeProtoBody())
    }

    internal func testFromProtoBody() throws {
        let protoData = Proto_FileUpdateTransactionBody.with { proto in
            proto.fileID = Resources.fileId.toProtobuf()
            proto.expirationTime = Resources.validStart.toProtobuf()
            proto.keys = KeyList.init(keys: [.single(Resources.publicKey)]).toProtobuf()
            proto.contents = Self.testContents
            proto.memo = "test memo"
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.fileUpdate = protoData
            proto.transactionID = Resources.txId.toProtobuf()
        }

        let tx = try FileUpdateTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.fileId, Resources.fileId)
        XCTAssertEqual(tx.expirationTime, Resources.validStart)
        XCTAssertEqual(tx.keys, KeyList.init(keys: [.single(Resources.publicKey)]))
        XCTAssertEqual(tx.fileMemo, "test memo")
        XCTAssertEqual(tx.contents, Self.testContents)
    }

    internal func testSetGetFileId() throws {
        let tx = FileUpdateTransaction.init()
        tx.fileId(Resources.fileId)

        XCTAssertEqual(tx.fileId, Resources.fileId)
    }

    internal func testSetGetFileMemo() throws {
        let tx = FileUpdateTransaction.init()
        tx.fileMemo(Self.testMemo)

        XCTAssertEqual(tx.fileMemo, Self.testMemo)
    }

    internal func testSetGetExpirationTime() throws {
        let tx = FileUpdateTransaction()
        tx.expirationTime(Resources.validStart)

        XCTAssertEqual(tx.expirationTime, Resources.validStart)
    }

    internal func testClearMemo() throws {
        let tx = FileUpdateTransaction.init()
        tx.fileMemo(Self.testMemo)

        XCTAssertEqual(tx.fileMemo, Self.testMemo)
    }
}
