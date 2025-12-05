// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class TokenMintTransactionUnitTests: HieroUnitTestCase, TransactionTestable {
    typealias TransactionType = TokenMintTransaction

    private static let testTokenId: TokenId = "4.2.0"
    private static let testAmount: UInt64 = 10
    private static let testMetadata = [Data([1, 2, 3, 4, 5])]

    static func makeTransaction() throws -> TokenMintTransaction {
        try TokenMintTransaction()
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .sign(TestConstants.privateKey)
            .tokenId(testTokenId)
            .amount(testAmount)
            .freeze()
    }

    private static func makeMetadataTransaction() throws -> TokenMintTransaction {
        try TokenMintTransaction()
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .sign(TestConstants.privateKey)
            .tokenId(testTokenId)
            .metadata(testMetadata)
            .freeze()
    }

    internal func test_Serialize() throws {
        try assertTransactionSerializes()
    }

    internal func test_ToFromBytes() throws {
        try assertTransactionRoundTrips()
    }

    internal func test_SerializeMetadata() throws {
        let tx = try Self.makeMetadataTransaction().makeProtoBody()

        SnapshotTesting.assertSnapshot(of: tx, as: .description)
    }

    internal func test_ToFromBytesMetadata() throws {
        let tx = try Self.makeMetadataTransaction()

        let tx2 = try Transaction.fromBytes(tx.toBytes())

        XCTAssertEqual(try tx.makeProtoBody(), try tx2.makeProtoBody())
    }

    internal func test_FromProtoBody() throws {
        let protoData = Proto_TokenMintTransactionBody.with { proto in
            proto.token = Self.testTokenId.toProtobuf()
            proto.amount = Self.testAmount
            proto.metadata = Self.testMetadata
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.tokenMint = protoData
            proto.transactionID = TestConstants.transactionId.toProtobuf()
        }

        let tx = try TokenMintTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.tokenId, Self.testTokenId)
        XCTAssertEqual(tx.amount, Self.testAmount)
        XCTAssertEqual(tx.metadata, Self.testMetadata)
    }

    internal func test_GetSetTokenId() {
        let tx = TokenMintTransaction()
        tx.tokenId(Self.testTokenId)

        XCTAssertEqual(tx.tokenId, Self.testTokenId)
    }

    internal func test_GetSetAmount() {
        let tx = TokenMintTransaction()
        tx.amount(Self.testAmount)

        XCTAssertEqual(tx.amount, Self.testAmount)
    }

    internal func test_GetSetMetadata() {
        let tx = TokenMintTransaction()
        tx.metadata(Self.testMetadata)

        XCTAssertEqual(tx.metadata, Self.testMetadata)
    }
}
