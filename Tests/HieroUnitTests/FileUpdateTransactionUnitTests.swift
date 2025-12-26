// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class FileUpdateTransactionUnitTests: HieroUnitTestCase, TransactionTestable {
    typealias TransactionType = FileUpdateTransaction

    private static let testMemo = "test Memo"
    private static let testContents: Data = "[swift::unit::fileUpdate::1]".data(using: .utf8)!

    static func makeTransaction() throws -> FileUpdateTransaction {
        try FileUpdateTransaction()
            .nodeAccountIds([AccountId("0.0.5005"), AccountId("0.0.5006")])
            .transactionId(
                TransactionId(
                    accountId: 5006, validStart: Timestamp(seconds: 1_554_158_542, subSecondNanos: 0), scheduled: false)
            )
            .fileId("1.2.4")
            .contents(Self.testContents)
            .expirationTime(Timestamp(seconds: 1_554_158_728, subSecondNanos: 0))
            .keys(.init(keys: [.single(TestConstants.publicKey)]))
            .maxTransactionFee(.fromTinybars(100_000))
            .fileMemo("Hello memo")
            .freeze()
            .sign(TestConstants.privateKey)
    }

    internal func test_Serialize() throws {
        try assertTransactionSerializes()
    }

    internal func test_ToFromBytes() throws {
        try assertTransactionRoundTrips()
    }

    internal func test_FromProtoBody() throws {
        let protoData = Proto_FileUpdateTransactionBody.with { proto in
            proto.fileID = TestConstants.fileId.toProtobuf()
            proto.expirationTime = TestConstants.validStart.toProtobuf()
            proto.keys = KeyList.init(keys: [.single(TestConstants.publicKey)]).toProtobuf()
            proto.contents = Self.testContents
            proto.memo = "test memo"
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.fileUpdate = protoData
            proto.transactionID = TestConstants.transactionId.toProtobuf()
        }

        let tx = try FileUpdateTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.fileId, TestConstants.fileId)
        XCTAssertEqual(tx.expirationTime, TestConstants.validStart)
        XCTAssertEqual(tx.keys, KeyList.init(keys: [.single(TestConstants.publicKey)]))
        XCTAssertEqual(tx.fileMemo, "test memo")
        XCTAssertEqual(tx.contents, Self.testContents)
    }

    internal func test_SetGetFileId() throws {
        let tx = FileUpdateTransaction.init()
        tx.fileId(TestConstants.fileId)

        XCTAssertEqual(tx.fileId, TestConstants.fileId)
    }

    internal func test_SetGetFileMemo() throws {
        let tx = FileUpdateTransaction.init()
        tx.fileMemo(Self.testMemo)

        XCTAssertEqual(tx.fileMemo, Self.testMemo)
    }

    internal func test_SetGetExpirationTime() throws {
        let tx = FileUpdateTransaction()
        tx.expirationTime(TestConstants.validStart)

        XCTAssertEqual(tx.expirationTime, TestConstants.validStart)
    }

    internal func test_ClearMemo() throws {
        let tx = FileUpdateTransaction.init()
        tx.fileMemo(Self.testMemo)

        XCTAssertEqual(tx.fileMemo, Self.testMemo)
    }
}
