// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class TokenUnfreezeTransactionUnitTests: HieroUnitTestCase, TransactionTestable {
    typealias TransactionType = TokenUnfreezeTransaction

    private static let testAccountId: AccountId = 222
    private static let testTokenId: TokenId = "6.5.4"

    static func makeTransaction() throws -> TokenUnfreezeTransaction {
        try TokenUnfreezeTransaction()
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .sign(TestConstants.privateKey)
            .accountId(testAccountId)
            .tokenId(testTokenId)
            .freeze()
    }

    internal func test_Serialize() throws {
        try assertTransactionSerializes()
    }

    internal func test_ToFromBytes() throws {
        try assertTransactionRoundTrips()
    }

    internal func test_FromProtoBody() throws {
        let protoData = Proto_TokenUnfreezeAccountTransactionBody.with { proto in
            proto.account = Self.testAccountId.toProtobuf()
            proto.token = Self.testTokenId.toProtobuf()
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.tokenUnfreeze = protoData
            proto.transactionID = TestConstants.transactionId.toProtobuf()
        }

        let tx = try TokenUnfreezeTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.accountId, Self.testAccountId)
        XCTAssertEqual(tx.tokenId, Self.testTokenId)
    }

    internal func test_GetSetAccountId() {
        let tx = TokenUnfreezeTransaction()
        tx.accountId(Self.testAccountId)

        XCTAssertEqual(tx.accountId, Self.testAccountId)
    }

    internal func test_GetSetTokenId() {
        let tx = TokenUnfreezeTransaction()
        tx.tokenId(Self.testTokenId)

        XCTAssertEqual(tx.tokenId, Self.testTokenId)
    }
}
