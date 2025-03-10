// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class TokenUnpauseTransactionTests: XCTestCase {
    private static let testTokenId: TokenId = "4.2.0"

    private static func makeTransaction() throws -> TokenUnpauseTransaction {
        try TokenUnpauseTransaction()
            .nodeAccountIds(Resources.nodeAccountIds)
            .transactionId(Resources.txId)
            .sign(Resources.privateKey)
            .tokenId(testTokenId)
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

    internal func testFromProtoBody() throws {
        let protoData = Proto_TokenUnpauseTransactionBody.with { proto in
            proto.token = Self.testTokenId.toProtobuf()
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.tokenUnpause = protoData
            proto.transactionID = Resources.txId.toProtobuf()
        }

        let tx = try TokenUnpauseTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.tokenId, Self.testTokenId)
    }

    internal func testGetSetTokenId() {
        let tx = TokenUnpauseTransaction()
        tx.tokenId(Self.testTokenId)

        XCTAssertEqual(tx.tokenId, Self.testTokenId)
    }
}
