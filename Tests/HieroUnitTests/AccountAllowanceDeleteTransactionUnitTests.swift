// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class AccountAllowanceDeleteTransactionUnitTests: HieroUnitTestCase, TransactionTestable {
    typealias TransactionType = AccountAllowanceDeleteTransaction

    private static let nftAllowance = NftRemoveAllowance(tokenId: 118, ownerAccountId: 999, serials: [23, 21])

    static func makeTransaction() throws -> AccountAllowanceDeleteTransaction {
        let ownerId: AccountId = "5.6.7"

        let invalidTokenIds: [TokenId] = ["4.4.4", "8.8.8"]

        return try AccountAllowanceDeleteTransaction()
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .sign(TestConstants.privateKey)
            .deleteAllTokenNftAllowances(invalidTokenIds[0].nft(123), ownerId)
            .deleteAllTokenNftAllowances(invalidTokenIds[0].nft(456), ownerId)
            .deleteAllTokenNftAllowances(invalidTokenIds[1].nft(456), ownerId)
            .deleteAllTokenNftAllowances(invalidTokenIds[0].nft(789), ownerId)
            .maxTransactionFee(Hbar.fromTinybars(100_000))
            .freeze()
    }

    internal func test_Serialize() throws {
        try assertTransactionSerializes()
    }

    internal func test_ToFromBytes() throws {
        try assertTransactionRoundTrips()
    }

    internal func test_FromProtoBody() throws {
        let protoData = Proto_CryptoDeleteAllowanceTransactionBody.with { proto in
            proto.nftAllowances = [Self.nftAllowance].toProtobuf()
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.cryptoDeleteAllowance = protoData
            proto.transactionID = TestConstants.transactionId.toProtobuf()
        }

        let tx = try AccountAllowanceDeleteTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.nftAllowances, [Self.nftAllowance])
    }

    internal func test_GetSetNftAllowance() {
        let tx = AccountAllowanceDeleteTransaction()
        tx.deleteAllTokenNftAllowances(TokenId(num: 118).nft(23), 999)
            .deleteAllTokenNftAllowances(TokenId(num: 118).nft(21), 999)

        XCTAssertEqual(tx.nftAllowances, [Self.nftAllowance])
    }
}
