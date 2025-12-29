// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class TokenBurnTransactionUnitTests: HieroUnitTestCase, TransactionTestable {
    typealias TransactionType = TokenBurnTransaction

    static func makeTransaction() throws -> TokenBurnTransaction {
        try TokenBurnTransaction()
            .nodeAccountIds([AccountId("0.0.5005"), AccountId("0.0.5006")])
            .transactionId(
                TransactionId(
                    accountId: 5005, validStart: Timestamp(seconds: 1_554_158_542, subSecondNanos: 0), scheduled: false)
            )
            .tokenId(TokenId.fromString("0.1.2"))
            .amount(54)
            .maxTransactionFee(1)
            .freeze()
            .sign(TestConstants.privateKey)
    }

    private static func makeTransactionNft() throws -> TokenBurnTransaction {
        try TokenBurnTransaction()
            .nodeAccountIds([AccountId("0.0.5005"), AccountId("0.0.5006")])
            .transactionId(
                TransactionId(
                    accountId: 5005, validStart: Timestamp(seconds: 1_554_158_542, subSecondNanos: 0), scheduled: false)
            )
            .tokenId(TokenId.fromString("0.1.2"))
            .maxTransactionFee(1)
            .setSerials([1, 2, 3])
            .freeze()
            .sign(TestConstants.privateKey)

    }

    internal func test_Serialize() throws {
        try assertTransactionSerializes()
    }

    internal func test_ToFromBytes() throws {
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

    internal func test_SetGetTokenId() {
        let tx = TokenBurnTransaction.init()

        let tx2 = tx.tokenId("0.0.123")

        XCTAssertEqual(tx2.tokenId, try TokenId.fromString("0.0.123"))
    }

    internal func test_SetGetSerials() throws {
        let tx = TokenBurnTransaction.init()

        let tx2 = tx.setSerials([1, 2, 3])

        XCTAssertEqual(tx2.serials, [1, 2, 3])
    }

    internal func test_SetGetAmount() {
        let tx = TokenBurnTransaction.init()

        let tx2 = tx.amount(64)

        XCTAssertEqual(tx2.amount, 64)
    }
}
