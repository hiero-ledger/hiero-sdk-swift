// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class TokenClaimAirdropTransactionTests: XCTestCase {
    private static func makeTransaction() throws -> TokenClaimAirdropTransaction {
        let pendingAirdropIds: [PendingAirdropId] = [
            .init(senderId: AccountId("0.2.123"), receiverId: AccountId("0.2.5"), tokenId: TokenId("0.0.321")),
            .init(senderId: AccountId("0.2.134"), receiverId: AccountId("0.2.6"), nftId: NftId("0.0.321/2")),
        ]

        let tx = TokenClaimAirdropTransaction()

        try tx.pendingAirdropIds(pendingAirdropIds)
            .transactionId(Resources.txId)
            .nodeAccountIds(Resources.nodeAccountIds)
            .maxTransactionFee(Hbar(2))
            .freeze()
            .sign(Resources.privateKey)

        return tx
    }

    func testSerialize() throws {
        let tx = try Self.makeTransaction().makeProtoBody()
        assertSnapshot(matching: tx, as: .description)
    }

    func testToFromBytes() throws {
        let tx = try Self.makeTransaction()
        let tx2 = try Transaction.fromBytes(tx.toBytes())

        XCTAssertEqual(try tx.makeProtoBody(), try tx2.makeProtoBody())
    }

    func testFromProtoBody() throws {
        let protoData = Proto_TokenClaimAirdropTransactionBody.with { proto in
            proto.pendingAirdrops = [
                PendingAirdropId.init(
                    senderId: AccountId(num: 415),
                    receiverId: AccountId(num: 6),
                    tokenId: TokenId(num: 312)
                ).toProtobuf(),
                PendingAirdropId.init(
                    senderId: AccountId(num: 134),
                    receiverId: AccountId(num: 6),
                    nftId: NftId("0.0.312/2")
                ).toProtobuf(),
            ]
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.tokenClaimAirdrop = protoData
            proto.transactionID = Resources.txId.toProtobuf()
        }

        let tx = try TokenClaimAirdropTransaction(protobuf: protoBody, protoData)

        let nftIds = tx.pendingAirdropIds.compactMap { $0.nftId }
        let tokenIds = tx.pendingAirdropIds.compactMap { $0.tokenId }

        XCTAssertEqual(nftIds.count, 1)
        XCTAssertEqual(tokenIds.count, 1)
        XCTAssertTrue(tokenIds.contains(TokenId(num: 312)))
        XCTAssertTrue(nftIds.contains(TokenId(num: 312).nft(2)))
    }

    func testGetSetPendingAirdropIds() throws {
        let pendingAirdropIds = [
            PendingAirdropId.init(
                senderId: AccountId(num: 415),
                receiverId: AccountId(num: 6),
                tokenId: TokenId(num: 420)
            ),
            PendingAirdropId.init(
                senderId: AccountId(num: 134),
                receiverId: AccountId(num: 6),
                nftId: NftId("0.0.312/2")
            ),
        ]

        let tx = TokenClaimAirdropTransaction()
        tx.pendingAirdropIds(pendingAirdropIds)

        let resultPendingAirdropIds = tx.pendingAirdropIds

        let nftIds = resultPendingAirdropIds.compactMap { $0.nftId }
        let tokenIds = resultPendingAirdropIds.compactMap { $0.tokenId }

        XCTAssertEqual(nftIds.count, 1)
        XCTAssertEqual(tokenIds.count, 1)
        XCTAssertTrue(tokenIds.contains(TokenId(num: 420)))
        XCTAssertTrue(nftIds.contains(TokenId(num: 312).nft(2)))
    }

    func testGetSetAddPendingAirdropId() {
        let tx = TokenClaimAirdropTransaction()
        tx.addPendingAirdropId(
            PendingAirdropId.init(
                senderId: AccountId(num: 415),
                receiverId: AccountId(num: 6),
                tokenId: TokenId(num: 312)
            ))

        let pendingAirdropIds = tx.pendingAirdropIds

        let tokenIds = pendingAirdropIds.compactMap { $0.tokenId }

        XCTAssertTrue(tokenIds.contains(TokenId(num: 312)))
    }
}
