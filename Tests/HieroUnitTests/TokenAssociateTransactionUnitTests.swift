// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class TokenAssociateTransactionUnitTests: HieroUnitTestCase, TransactionTestable {
    typealias TransactionType = TokenAssociateTransaction

    static func makeTransaction() throws -> TokenAssociateTransaction {
        try TokenAssociateTransaction()
            .nodeAccountIds([AccountId("0.0.5005"), AccountId("0.0.5006")])
            .transactionId(
                TransactionId(
                    accountId: 5005, validStart: Timestamp(seconds: 1_554_158_542, subSecondNanos: 0), scheduled: false)
            )
            .accountId(AccountId.fromString("0.0.435"))
            .tokenIds([TokenId.fromString("1.2.3")])
            .freeze()
            .sign(TestConstants.privateKey)
    }

    internal func test_Serialize() throws {
        try assertTransactionSerializes()
    }

    internal func test_ToFromBytes() throws {
        try assertTransactionRoundTrips()
    }

    internal func test_FromProtoBody() throws {
        let protoData = Proto_TokenAssociateTransactionBody.with { proto in
            proto.account = TestConstants.accountId.toProtobuf()
            proto.tokens = [TestConstants.tokenId.toProtobuf()]
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.tokenAssociate = protoData
            proto.transactionID = TestConstants.transactionId.toProtobuf()
        }

        let tx = try TokenAssociateTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.accountId, TestConstants.accountId)
        XCTAssertEqual(tx.tokenIds, [TestConstants.tokenId])
    }

    internal func test_SetGetAccountId() {
        let tx = TokenAssociateTransaction.init()

        let tx2 = tx.accountId("0.0.123")

        XCTAssertEqual(tx2.accountId, try AccountId.fromString("0.0.123"))
    }

    internal func test_SetGetTokenId() throws {
        let tx = TokenAssociateTransaction.init()

        let tx2 = tx.tokenIds([try TokenId.fromString("0.0.123")])

        XCTAssertEqual(tx2.tokenIds, [try TokenId.fromString("0.0.123")])
    }
}
