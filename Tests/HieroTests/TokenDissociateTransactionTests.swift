// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class TokenDissociateTransactionTests: XCTestCase {
    internal static let testAccountId: AccountId = "6.9.0"

    internal static let testTokenIds: [TokenId] = ["4.2.0", "4.2.1", "4.2.2"]

    private static func makeTransaction() throws -> TokenDissociateTransaction {
        try TokenDissociateTransaction()
            .nodeAccountIds(Resources.nodeAccountIds)
            .transactionId(Resources.txId)
            .sign(Resources.privateKey)
            .tokenIds(testTokenIds)
            .accountId(testAccountId)
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
        let protoData = Proto_TokenDissociateTransactionBody.with { proto in
            proto.account = Self.testAccountId.toProtobuf()
            proto.tokens = Self.testTokenIds.toProtobuf()
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.tokenDissociate = protoData
            proto.transactionID = Resources.txId.toProtobuf()
        }

        let tx = try TokenDissociateTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.accountId, Self.testAccountId)
        XCTAssertEqual(tx.tokenIds, Self.testTokenIds)
    }

    internal func testGetSetAccountId() {
        let tx = TokenDissociateTransaction()
        tx.accountId(Self.testAccountId)

        XCTAssertEqual(tx.accountId, Self.testAccountId)
    }

    internal func testGetSetTokenIds() {
        let tx = TokenDissociateTransaction()
        tx.tokenIds(Self.testTokenIds)

        XCTAssertEqual(tx.tokenIds, Self.testTokenIds)
    }
}
