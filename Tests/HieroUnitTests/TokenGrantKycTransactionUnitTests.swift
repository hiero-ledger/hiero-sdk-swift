// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class TokenGrantKycTransactionUnitTests: HieroUnitTestCase, TransactionTestable {
    typealias TransactionType = TokenGrantKycTransaction

    internal static let testAccountId: AccountId = "6.9.0"

    internal static let testTokenId: TokenId = "4.2.0"

    static func makeTransaction() throws -> TokenGrantKycTransaction {
        try TokenGrantKycTransaction()
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .sign(TestConstants.privateKey)
            .tokenId(testTokenId)
            .accountId(testAccountId)
            .freeze()
    }

    internal func test_Serialize() throws {
        try assertTransactionSerializes()
    }

    internal func test_ToFromBytes() throws {
        try assertTransactionRoundTrips()
    }

    internal func test_FromProtoBody() throws {
        let protoData = Proto_TokenGrantKycTransactionBody.with { proto in
            proto.account = Self.testAccountId.toProtobuf()
            proto.token = Self.testTokenId.toProtobuf()
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.tokenGrantKyc = protoData
            proto.transactionID = TestConstants.transactionId.toProtobuf()
        }

        let tx = try TokenGrantKycTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.accountId, Self.testAccountId)
        XCTAssertEqual(tx.tokenId, Self.testTokenId)
    }

    internal func test_GetSetAccountId() {
        let tx = TokenGrantKycTransaction()
        tx.accountId(Self.testAccountId)

        XCTAssertEqual(tx.accountId, Self.testAccountId)
    }

    internal func test_GetSetTokenId() {
        let tx = TokenGrantKycTransaction()
        tx.tokenId(Self.testTokenId)

        XCTAssertEqual(tx.tokenId, Self.testTokenId)
    }
}
