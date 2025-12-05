// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class FileDeleteTransactionUnitTests: HieroUnitTestCase, TransactionTestable {
    typealias TransactionType = FileDeleteTransaction

    static func makeTransaction() throws -> FileDeleteTransaction {
        try FileDeleteTransaction()
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .sign(TestConstants.privateKey)
            .fileId("0.0.6006")
            .maxTransactionFee(.fromTinybars(100_000))
            .freeze()
    }

    internal func test_Serialize() throws {
        try assertTransactionSerializes()
    }

    internal func test_ToFromBytes() throws {
        try assertTransactionRoundTrips()
    }

    internal func test_FromProtoBody() throws {
        let protoData = Proto_FileDeleteTransactionBody.with { proto in
            proto.fileID = FileId(num: 6006).toProtobuf()
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.fileDelete = protoData
            proto.transactionID = TestConstants.transactionId.toProtobuf()
        }

        let tx = try FileDeleteTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.fileId, 6006)
    }

    internal func test_GetSetFileId() {
        let tx = FileDeleteTransaction()

        tx.fileId(1234)

        XCTAssertEqual(tx.fileId, 1234)
    }
}
