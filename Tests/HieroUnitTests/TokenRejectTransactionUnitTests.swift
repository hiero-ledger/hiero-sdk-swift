// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class TokenRejectTransactionUnitTests: HieroUnitTestCase, TransactionTestable {
    typealias TransactionType = TokenRejectTransaction

    private static let testPrivateKey = PrivateKey(
        "302e020100300506032b657004220420db484b828e64b2d8f12ce3c0a0e93a0b8cce7af1bb8f39c97732394482538e10")
    private static let testOwnerId = AccountId("0.0.12345")

    private static let testTokenIds: [TokenId] = [TokenId("4.2.0"), TokenId("4.2.1"), TokenId("4.2.2")]

    private static let testNftIds: [NftId] = [NftId("4.2.3/1"), NftId("4.2.4/2"), NftId("4.2.5/3")]

    static func makeTransaction() throws -> TokenRejectTransaction {
        try TokenRejectTransaction()
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .owner(testOwnerId)
            .tokenIds(testTokenIds)
            .nftIds(testNftIds)
            .freeze()
            .sign(testPrivateKey)
    }

    internal func test_Serialize() throws {
        try assertTransactionSerializes()
    }

    internal func test_ToFromBytes() throws {
        try assertTransactionRoundTrips()
    }

    internal func test_FromProtoBody() throws {
        var protoTokenReferences: [Proto_TokenReference] = []

        for tokenId in Self.testTokenIds {
            protoTokenReferences.append(.with { $0.fungibleToken = tokenId.toProtobuf() })
        }

        for nftId in Self.testNftIds {
            protoTokenReferences.append(.with { $0.nft = nftId.toProtobuf() })
        }

        let protoData = Proto_TokenRejectTransactionBody.with { proto in
            proto.owner = Self.testOwnerId.toProtobuf()
            proto.rejections = protoTokenReferences
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.tokenReject = protoData
            proto.transactionID = TestConstants.transactionId.toProtobuf()
        }

        let tx = try TokenRejectTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.owner, Self.testOwnerId)
        XCTAssertEqual(tx.tokenIds, Self.testTokenIds)
        XCTAssertEqual(tx.nftIds, Self.testNftIds)
    }

    internal func test_GetSetOwner() {
        let tx = TokenRejectTransaction()
        tx.owner(Self.testOwnerId)

        XCTAssertEqual(tx.owner, Self.testOwnerId)
    }

    internal func test_GetSetTokenIds() {
        let tx = TokenRejectTransaction()
        tx.tokenIds(Self.testTokenIds)

        XCTAssertEqual(tx.tokenIds, Self.testTokenIds)
    }

    internal func test_GetSetNftIds() {
        let tx = TokenRejectTransaction()
        tx.nftIds(Self.testNftIds)

        XCTAssertEqual(tx.nftIds, Self.testNftIds)
    }

    internal func test_GetSetAddTokenId() {
        let tx = TokenRejectTransaction()
        tx.addTokenId(Self.testTokenIds[0])
        tx.addTokenId(Self.testTokenIds[1])

        XCTAssertEqual(tx.tokenIds[0], Self.testTokenIds[0])
        XCTAssertEqual(tx.tokenIds[1], Self.testTokenIds[1])
    }

    internal func test_GetSetAddNftId() {
        let tx = TokenRejectTransaction()
        tx.addNftId(Self.testNftIds[0])
        tx.addNftId(Self.testNftIds[1])

        XCTAssertEqual(tx.nftIds[0], Self.testNftIds[0])
        XCTAssertEqual(tx.nftIds[1], Self.testNftIds[1])
    }
}
