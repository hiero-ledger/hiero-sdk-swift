// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class TokenUnfreezeTransactionTests: XCTestCase {
    private static let testAccountId: AccountId = 222
    private static let testTokenId: TokenId = "6.5.4"

    private static func makeTransaction() throws -> TokenUnfreezeTransaction {
        try TokenUnfreezeTransaction()
            .nodeAccountIds(Resources.nodeAccountIds)
            .transactionId(Resources.txId)
            .sign(Resources.privateKey)
            .accountId(testAccountId)
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
        let protoData = Proto_TokenUnfreezeAccountTransactionBody.with { proto in
            proto.account = Self.testAccountId.toProtobuf()
            proto.token = Self.testTokenId.toProtobuf()
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.tokenUnfreeze = protoData
            proto.transactionID = Resources.txId.toProtobuf()
        }

        let tx = try TokenUnfreezeTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.accountId, Self.testAccountId)
        XCTAssertEqual(tx.tokenId, Self.testTokenId)
    }

    internal func testGetSetAccountId() {
        let tx = TokenUnfreezeTransaction()
        tx.accountId(Self.testAccountId)

        XCTAssertEqual(tx.accountId, Self.testAccountId)
    }

    internal func testGetSetTokenId() {
        let tx = TokenUnfreezeTransaction()
        tx.tokenId(Self.testTokenId)

        XCTAssertEqual(tx.tokenId, Self.testTokenId)
    }
}
