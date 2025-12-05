// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class PrngTransactionUnitTests: HieroUnitTestCase, TransactionTestable {
    typealias TransactionType = PrngTransaction

    static func makeTransaction() throws -> PrngTransaction {
        try PrngTransaction()
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .sign(TestConstants.privateKey)
            .freeze()
    }

    private static func makeTransaction2() throws -> PrngTransaction {
        try PrngTransaction()
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .sign(TestConstants.privateKey)
            .range(100)
            .freeze()
    }

    internal func test_Serialize() throws {
        try assertTransactionSerializes()
    }

    internal func test_ToFromBytes() throws {
        try assertTransactionRoundTrips()
    }

    internal func test_Serialize2() throws {
        let tx = try Self.makeTransaction2().makeProtoBody()

        SnapshotTesting.assertSnapshot(of: tx, as: .description)
    }

    internal func test_ToFromBytes2() throws {
        let tx = try Self.makeTransaction2()

        let tx2 = try Transaction.fromBytes(tx.toBytes())

        XCTAssertEqual(try tx.makeProtoBody(), try tx2.makeProtoBody())
    }

    internal func test_FromProtoBody() throws {
        let protoData = Proto_UtilPrngTransactionBody.with { proto in
            proto.range = 100
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.utilPrng = protoData
            proto.transactionID = TestConstants.transactionId.toProtobuf()
        }

        let tx = try PrngTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.range, 100)
    }

    internal func test_GetSetRange() {
        let tx = PrngTransaction()
        tx.range(100)

        XCTAssertEqual(tx.range, 100)
    }
}
