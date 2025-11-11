// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal class AccountAllowanceDeleteTransactionTests: XCTestCase {
    private static let nftAllowance = NftRemoveAllowance(tokenId: 118, ownerAccountId: 999, serials: [23, 21])

    private static func makeTransaction() throws -> AccountAllowanceDeleteTransaction {
        let ownerId: AccountId = "5.6.7"

        let invalidTokenIds: [TokenId] = ["4.4.4", "8.8.8"]

        return try AccountAllowanceDeleteTransaction()
            .nodeAccountIds(Resources.nodeAccountIds)
            .transactionId(Resources.txId)
            .sign(Resources.privateKey)
            .deleteAllTokenNftAllowances(invalidTokenIds[0].nft(123), ownerId)
            .deleteAllTokenNftAllowances(invalidTokenIds[0].nft(456), ownerId)
            .deleteAllTokenNftAllowances(invalidTokenIds[1].nft(456), ownerId)
            .deleteAllTokenNftAllowances(invalidTokenIds[0].nft(789), ownerId)
            .maxTransactionFee(Hbar.fromTinybars(100_000))
            .freeze()
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
        let protoData = Proto_CryptoDeleteAllowanceTransactionBody.with { proto in
            proto.nftAllowances = [Self.nftAllowance].toProtobuf()
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.cryptoDeleteAllowance = protoData
            proto.transactionID = Resources.txId.toProtobuf()
        }

        let tx = try AccountAllowanceDeleteTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.nftAllowances, [Self.nftAllowance])
    }

    internal func testGetSetNftAllowance() {
        let tx = AccountAllowanceDeleteTransaction()
        tx.deleteAllTokenNftAllowances(TokenId(num: 118).nft(23), 999)
            .deleteAllTokenNftAllowances(TokenId(num: 118).nft(21), 999)

        XCTAssertEqual(tx.nftAllowances, [Self.nftAllowance])
    }
}
