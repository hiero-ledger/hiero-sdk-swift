// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class TokenDissociateTransactionUnitTests: HieroUnitTestCase, TransactionTestable {
    typealias TransactionType = TokenDissociateTransaction

    internal static let testAccountId: AccountId = "6.9.0"

    internal static let testTokenIds: [TokenId] = ["4.2.0", "4.2.1", "4.2.2"]

    static func makeTransaction() throws -> TokenDissociateTransaction {
        try TokenDissociateTransaction()
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .sign(TestConstants.privateKey)
            .tokenIds(testTokenIds)
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
        let protoData = Proto_TokenDissociateTransactionBody.with { proto in
            proto.account = Self.testAccountId.toProtobuf()
            proto.tokens = Self.testTokenIds.toProtobuf()
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.tokenDissociate = protoData
            proto.transactionID = TestConstants.transactionId.toProtobuf()
        }

        let tx = try TokenDissociateTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.accountId, Self.testAccountId)
        XCTAssertEqual(tx.tokenIds, Self.testTokenIds)
    }

    internal func test_GetSetAccountId() {
        let tx = TokenDissociateTransaction()
        tx.accountId(Self.testAccountId)

        XCTAssertEqual(tx.accountId, Self.testAccountId)
    }

    internal func test_GetSetTokenIds() {
        let tx = TokenDissociateTransaction()
        tx.tokenIds(Self.testTokenIds)

        XCTAssertEqual(tx.tokenIds, Self.testTokenIds)
    }
}
