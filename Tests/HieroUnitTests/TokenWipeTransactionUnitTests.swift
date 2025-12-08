// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class TokenWipeTransactionUnitTests: HieroUnitTestCase, TransactionTestable {
    typealias TransactionType = TokenWipeTransaction

    private static let testAccountId: AccountId = "0.6.9"
    private static let testTokenId: TokenId = "4.2.0"
    private static let testAmount: UInt64 = 4
    private static let testSerials: [UInt64] = [8, 9, 10]

    static func makeTransaction() throws -> TokenWipeTransaction {
        try TokenWipeTransaction()
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .sign(TestConstants.privateKey)
            .tokenId(testTokenId)
            .accountId(testAccountId)
            .amount(testAmount)
            .freeze()
    }

    private static func makeTransactionNft() throws -> TokenWipeTransaction {
        try TokenWipeTransaction()
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .sign(TestConstants.privateKey)
            .tokenId(testTokenId)
            .accountId(testAccountId)
            .serials(testSerials)
            .freeze()
    }

    internal func test_SerializeFungible() throws {
        try assertTransactionSerializes()
    }

    internal func test_ToFromBytesFungieble() throws {
        try assertTransactionRoundTrips()
    }

    internal func test_SerializeNft() throws {
        let tx = try Self.makeTransactionNft().makeProtoBody()

        SnapshotTesting.assertSnapshot(of: tx, as: .description)
    }

    internal func test_ToFromBytesNft() throws {
        let tx = try Self.makeTransactionNft()

        let tx2 = try Transaction.fromBytes(tx.toBytes())

        XCTAssertEqual(try tx.makeProtoBody(), try tx2.makeProtoBody())
    }

    internal func test_FromProtoBody() throws {
        let protoData = Proto_TokenWipeAccountTransactionBody.with { proto in
            proto.token = Self.testTokenId.toProtobuf()
            proto.account = Self.testAccountId.toProtobuf()
            proto.amount = Self.testAmount
            proto.serialNumbers = Self.testSerials.map(Int64.init(bitPattern:))
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.tokenWipe = protoData
            proto.transactionID = TestConstants.transactionId.toProtobuf()
        }

        let tx = try TokenWipeTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.tokenId, Self.testTokenId)
        XCTAssertEqual(tx.accountId, Self.testAccountId)
        XCTAssertEqual(tx.amount, Self.testAmount)
        XCTAssertEqual(tx.serials, Self.testSerials)

    }

    internal func test_GetSetTokenId() {
        let tx = TokenWipeTransaction()
        tx.tokenId(Self.testTokenId)

        XCTAssertEqual(tx.tokenId, Self.testTokenId)
    }

    internal func test_GetSetAccountId() {
        let tx = TokenWipeTransaction()
        tx.accountId(Self.testAccountId)

        XCTAssertEqual(tx.accountId, Self.testAccountId)
    }

    internal func test_GetSetAmount() {
        let tx = TokenWipeTransaction()
        tx.amount(Self.testAmount)

        XCTAssertEqual(tx.amount, Self.testAmount)
    }

    internal func test_GetSetSerialNumbers() {
        let tx = TokenWipeTransaction()
        tx.serials(Self.testSerials)

        XCTAssertEqual(tx.serials, Self.testSerials)
    }
}
