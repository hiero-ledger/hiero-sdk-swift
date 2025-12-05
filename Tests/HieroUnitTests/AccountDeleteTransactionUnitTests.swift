// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class AccountDeleteTransactionUnitTests: HieroUnitTestCase, TransactionTestable {
    typealias TransactionType = AccountDeleteTransaction

    private static let testTransferAccountId = AccountId("0.0.5007")
    private static let testAccountId = TestConstants.accountId
    private static let testMaxTransactionFee = Hbar.fromTinybars(100_000)

    static func makeTransaction() throws -> AccountDeleteTransaction {
        try AccountDeleteTransaction()
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .transferAccountId(testTransferAccountId)
            .accountId(testAccountId)
            .maxTransactionFee(testMaxTransactionFee)
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
        let protoData = Proto_CryptoDeleteTransactionBody.with { proto in
            proto.deleteAccountID = Self.testAccountId.toProtobuf()
            proto.transferAccountID = Self.testTransferAccountId.toProtobuf()
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.cryptoDelete = protoData
            proto.transactionID = TestConstants.transactionId.toProtobuf()
        }

        let tx = try AccountDeleteTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.accountId, Self.testAccountId)
        XCTAssertEqual(tx.transferAccountId, Self.testTransferAccountId)
    }

    internal func test_GetSetAccountId() throws {
        let tx = AccountDeleteTransaction()
        tx.accountId(Self.testAccountId)

        XCTAssertEqual(tx.accountId, Self.testAccountId)
    }

    internal func test_GetSetTransferAccountId() throws {
        let tx = AccountDeleteTransaction()
        tx.transferAccountId(Self.testTransferAccountId)

        XCTAssertEqual(tx.transferAccountId, Self.testTransferAccountId)
    }
}
