// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class PrngTransactionTests: XCTestCase {
    private static func makeTransaction() throws -> PrngTransaction {
        try PrngTransaction()
            .nodeAccountIds(Resources.nodeAccountIds)
            .transactionId(Resources.txId)
            .sign(Resources.privateKey)
            .freeze()
    }

    private static func makeTransaction2() throws -> PrngTransaction {
        try PrngTransaction()
            .nodeAccountIds(Resources.nodeAccountIds)
            .transactionId(Resources.txId)
            .sign(Resources.privateKey)
            .range(100)
            .freeze()
    }

    internal func testSerialize() throws {
        let tx = try Self.makeTransaction().makeProtoBody()

        assertSnapshot(matching: tx, as: .description)
    }

    internal func testToFromBytes() throws {
        let tx = try Self.makeTransaction()

        let tx2 = try Transaction.fromBytes(tx.toBytes())

        XCTAssertEqual(try tx.makeProtoBody(), try tx2.makeProtoBody())
    }

    internal func testSerialize2() throws {
        let tx = try Self.makeTransaction2().makeProtoBody()

        assertSnapshot(matching: tx, as: .description)
    }

    internal func testToFromBytes2() throws {
        let tx = try Self.makeTransaction2()

        let tx2 = try Transaction.fromBytes(tx.toBytes())

        XCTAssertEqual(try tx.makeProtoBody(), try tx2.makeProtoBody())
    }

    internal func testFromProtoBody() throws {
        let protoData = Proto_UtilPrngTransactionBody.with { proto in
            proto.range = 100
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.utilPrng = protoData
            proto.transactionID = Resources.txId.toProtobuf()
        }

        let tx = try PrngTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.range, 100)
    }

    internal func testGetSetRange() {
        let tx = PrngTransaction()
        tx.range(100)

        XCTAssertEqual(tx.range, 100)
    }
}
