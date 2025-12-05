// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class FileCreateTransactionUnitTests: HieroUnitTestCase, TransactionTestable {
    typealias TransactionType = FileCreateTransaction

    private static let contents: Data = "[swift::unit::fileCreate::1]".data(using: .utf8)!
    private static let expirationTime = Timestamp(seconds: 1_554_158_728, subSecondNanos: 0)
    private static let keys: KeyList = [.single(TestConstants.publicKey)]
    private static let fileMemo = "Hello memo"

    static func makeTransaction() throws -> FileCreateTransaction {
        try FileCreateTransaction()
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .sign(TestConstants.privateKey)
            .maxTransactionFee(.fromTinybars(100_000))
            .contents(contents)
            .expirationTime(expirationTime)
            .keys(keys)
            .fileMemo(fileMemo)
            .freeze()
    }

    internal func test_Serialize() throws {
        try assertTransactionSerializes()
    }

    internal func test_ToFromBytes() throws {
        try assertTransactionRoundTrips()
    }

    internal func test_FromProtoBody() throws {
        let protoData = Proto_FileCreateTransactionBody.with { proto in
            proto.contents = Self.contents
            proto.expirationTime = Self.expirationTime.toProtobuf()
            proto.keys = Self.keys.toProtobuf()
            proto.memo = Self.fileMemo
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.fileCreate = protoData
            proto.transactionID = TestConstants.transactionId.toProtobuf()
        }

        let tx = try FileCreateTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.contents, Self.contents)
        XCTAssertEqual(tx.expirationTime, Self.expirationTime)
        XCTAssertEqual(tx.keys, Self.keys)
        XCTAssertEqual(tx.fileMemo, Self.fileMemo)
    }

    internal func test_GetSetContents() {
        let tx = FileCreateTransaction()

        XCTAssertEqual(tx.contents, Data())

        tx.contents(Self.contents)

        XCTAssertEqual(tx.contents, Self.contents)
    }

    internal func test_GetSetExpirationTime() {
        let tx = FileCreateTransaction()

        tx.expirationTime(Self.expirationTime)

        XCTAssertEqual(tx.expirationTime, Self.expirationTime)
    }

    internal func test_GetSetKeys() {
        let tx = FileCreateTransaction()

        XCTAssertEqual(tx.keys, [])

        tx.keys(Self.keys)

        XCTAssertEqual(tx.keys, Self.keys)
    }

    internal func test_GetSetFileMemo() {
        let tx = FileCreateTransaction()

        XCTAssertEqual(tx.fileMemo, "")

        tx.fileMemo(Self.fileMemo)

        XCTAssertEqual(tx.fileMemo, Self.fileMemo)
    }
}
