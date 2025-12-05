// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class AccountAllowanceApproveTransactionUnitTests: HieroUnitTestCase, TransactionTestable {
    typealias TransactionType = AccountAllowanceApproveTransaction

    private static let hbarAllowance = HbarAllowance(ownerAccountId: 10, spenderAccountId: 11, amount: 1)
    private static let tokenAllowance = TokenAllowance(tokenId: 9, ownerAccountId: 10, spenderAccountId: 11, amount: 1)
    private static let nftAllowance = TokenNftAllowance(
        tokenId: 9,
        ownerAccountId: 10,
        spenderAccountId: 11,
        serials: [8],
        approvedForAll: nil,
        delegatingSpenderAccountId: nil
    )

    static func makeTransaction() throws -> AccountAllowanceApproveTransaction {
        let ownerId: AccountId = "5.6.7"

        let invalidTokenIds: [TokenId] = [
            "2.2.2",
            "4.4.4",
            "6.6.6",
            "8.8.8",
        ]

        let invalidAccountIds: [AccountId] = [
            "1.1.1",
            "3.3.3",
            "5.5.5",
            "7.7.7",
            "9.9.9",
        ]

        return try AccountAllowanceApproveTransaction()
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .sign(TestConstants.privateKey)
            .approveHbarAllowance(ownerId, invalidAccountIds[0], Hbar(3))
            .approveTokenAllowance(invalidTokenIds[0], ownerId, invalidAccountIds[1], 6)
            .approveTokenNftAllowance(
                invalidTokenIds[1].nft(123),
                ownerId,
                invalidAccountIds[2]
            )
            .approveTokenNftAllowance(
                invalidTokenIds[1].nft(456),
                ownerId,
                invalidAccountIds[2]
            )
            .approveTokenNftAllowance(
                invalidTokenIds[3].nft(456),
                ownerId,
                invalidAccountIds[2]
            )
            .approveTokenNftAllowance(
                invalidTokenIds[1].nft(789),
                ownerId,
                invalidAccountIds[4]
            )
            .approveTokenNftAllowanceAllSerials(
                invalidTokenIds[2],
                ownerId,
                invalidAccountIds[3]
            )
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
        let protoData = Proto_CryptoApproveAllowanceTransactionBody.with { proto in
            proto.cryptoAllowances = [Self.hbarAllowance].toProtobuf()
            proto.tokenAllowances = [Self.tokenAllowance].toProtobuf()
            proto.nftAllowances = [Self.nftAllowance].toProtobuf()
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.cryptoApproveAllowance = protoData
            proto.transactionID = TestConstants.transactionId.toProtobuf()
        }

        let tx = try AccountAllowanceApproveTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.getHbarApprovals(), [Self.hbarAllowance])
        XCTAssertEqual(tx.getTokenApprovals(), [Self.tokenAllowance])
        XCTAssertEqual(tx.getNftApprovals(), [Self.nftAllowance])
    }

    internal func test_CheckProperties() throws {
        let tx = try Self.makeTransaction()

        XCTAssertFalse(tx.getHbarApprovals().isEmpty)
        XCTAssertFalse(tx.getTokenApprovals().isEmpty)
        XCTAssertFalse(tx.getNftApprovals().isEmpty)
    }

    internal func test_GetSetHbarAllowance() {
        let tx = AccountAllowanceApproveTransaction()
        tx.approveHbarAllowance(10, 11, 1)

        XCTAssertEqual(tx.getHbarApprovals(), [Self.hbarAllowance])
    }

    internal func test_GetSetTokenAllowance() {
        let tx = AccountAllowanceApproveTransaction()
        tx.approveTokenAllowance(9, 10, 11, 1)

        XCTAssertEqual(tx.getTokenApprovals(), [Self.tokenAllowance])
    }

    internal func test_GetSetNftAllowance() {
        let tx = AccountAllowanceApproveTransaction()

        tx.approveTokenNftAllowance(TokenId(num: 9).nft(8), 10, 11)

        XCTAssertEqual(tx.getNftApprovals(), [Self.nftAllowance])
    }
}
