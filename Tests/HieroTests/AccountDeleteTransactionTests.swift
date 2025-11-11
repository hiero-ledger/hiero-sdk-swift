// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal class AccountDeleteTransactionTests: XCTestCase {
    private static let testTransferAccountId = AccountId("0.0.5007")
    private static let testAccountId = Resources.accountId
    private static let testMaxTransactionFee = Hbar.fromTinybars(100_000)

    private static func makeTransaction() throws -> AccountDeleteTransaction {
        try AccountDeleteTransaction()
            .nodeAccountIds(Resources.nodeAccountIds)
            .transactionId(Resources.txId)
            .transferAccountId(testTransferAccountId)
            .accountId(testAccountId)
            .maxTransactionFee(testMaxTransactionFee)
            .freeze()
            .sign(Resources.privateKey)
    }

    internal func testSerialize() throws {
        let tx = try Self.makeTransaction().makeProtoBody()

        assertSnapshot(of: tx, as: .description)
    }

    internal func testToFromBytes() throws {
        let tx = try Self.makeTransaction()
        let tx2 = try Transaction.fromBytes(tx.toBytes())

        XCTAssertEqual(try tx.makeProtoBody(), try tx2.makeProtoBody())
    }

    internal func testFromProtoBody() throws {
        let protoData = Proto_CryptoDeleteTransactionBody.with { proto in
            proto.deleteAccountID = Self.testAccountId.toProtobuf()
            proto.transferAccountID = Self.testTransferAccountId.toProtobuf()
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.cryptoDelete = protoData
            proto.transactionID = Resources.txId.toProtobuf()
        }

        let tx = try AccountDeleteTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.accountId, Self.testAccountId)
        XCTAssertEqual(tx.transferAccountId, Self.testTransferAccountId)
    }

    internal func testGetSetAccountId() throws {
        let tx = AccountDeleteTransaction()
        tx.accountId(Self.testAccountId)

        XCTAssertEqual(tx.accountId, Self.testAccountId)
    }

    internal func testGetSetTransferAccountId() throws {
        let tx = AccountDeleteTransaction()
        tx.transferAccountId(Self.testTransferAccountId)

        XCTAssertEqual(tx.transferAccountId, Self.testTransferAccountId)
    }
}
