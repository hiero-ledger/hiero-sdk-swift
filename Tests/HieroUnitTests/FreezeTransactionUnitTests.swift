// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class FreezeTransactionUnitTests: HieroUnitTestCase, TransactionTestable {
    typealias TransactionType = FreezeTransaction

    private static let fileId: FileId = "4.5.6"
    private static let fileHash = Data(hexEncoded: "1723904587120938954702349857")!

    static func makeTransaction() throws -> FreezeTransaction {
        try FreezeTransaction()
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .sign(TestConstants.privateKey)
            .fileId(fileId)
            .fileHash(fileHash)
            .startTime(TestConstants.validStart)
            .freezeType(.freezeAbort)
            .freeze()
    }

    internal func test_Serialize() throws {
        try assertTransactionSerializes()
    }

    internal func test_ToFromBytes() throws {
        try assertTransactionRoundTrips()
    }

    internal func test_FromProtoBody() throws {
        let protoData = Proto_FreezeTransactionBody.with { proto in
            proto.updateFile = Self.fileId.toProtobuf()
            proto.fileHash = Self.fileHash
            proto.startTime = TestConstants.validStart.toProtobuf()
            proto.freezeType = .freezeAbort
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.freeze = protoData
            proto.transactionID = TestConstants.transactionId.toProtobuf()
        }

        let tx = try FreezeTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.fileId, Self.fileId)
        XCTAssertEqual(tx.fileHash, Self.fileHash)
        XCTAssertEqual(tx.startTime, TestConstants.validStart)
        XCTAssertEqual(tx.freezeType, .freezeAbort)
    }

    internal func test_GetSetFileId() {
        let tx = FreezeTransaction()
        tx.fileId(Self.fileId)

        XCTAssertEqual(tx.fileId, Self.fileId)
    }

    internal func test_GetSetFileHash() {
        let tx = FreezeTransaction()
        tx.fileHash(Self.fileHash)

        XCTAssertEqual(tx.fileHash, Self.fileHash)
    }

    internal func test_GetSetStartTime() {
        let tx = FreezeTransaction()
        tx.startTime(TestConstants.validStart)

        XCTAssertEqual(tx.startTime, TestConstants.validStart)
    }

    internal func test_GetSetFreezeType() {
        let tx = FreezeTransaction()
        tx.freezeType(.freezeAbort)

        XCTAssertEqual(tx.freezeType, .freezeAbort)
    }
}
