// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class TokenCreateTransactionUnitTests: HieroUnitTestCase, TransactionTestable {
    typealias TransactionType = TokenCreateTransaction

    static func makeTransaction() throws -> TokenCreateTransaction {
        try TokenCreateTransaction()
            .nodeAccountIds([AccountId("0.0.5005"), AccountId("0.0.5006")])
            .transactionId(
                TransactionId(
                    accountId: 5005, validStart: Timestamp(seconds: 1_554_158_542, subSecondNanos: 0), scheduled: false)
            )
            .initialSupply(30)
            .feeScheduleKey(.single(TestConstants.publicKey))
            .supplyKey(.single(TestConstants.publicKey))
            .adminKey(.single(TestConstants.publicKey))
            .autoRenewAccountId(AccountId.fromString("0.0.123"))
            .autoRenewPeriod(Duration.seconds(100))
            .decimals(3)
            .freezeDefault(true)
            .freezeKey(.single(TestConstants.publicKey))
            .wipeKey(.single(TestConstants.publicKey))
            .symbol("F")
            .kycKey(.single(TestConstants.publicKey))
            .pauseKey(.single(TestConstants.publicKey))
            .expirationTime(Timestamp(seconds: 1_554_158_557, subSecondNanos: 0))
            .treasuryAccountId(AccountId.fromString("0.0.456"))
            .name("flook")
            .tokenMemo("flook memo")
            .customFees([
                .fixed(
                    FixedFee(
                        amount: 3,
                        denominatingTokenId: try TokenId.fromString("4.3.2"),
                        feeCollectorAccountId: try AccountId.fromString("0.0.54")
                    ))
            ])
            .metadata(TestConstants.metadata)
            .metadataKey(.single(TestConstants.publicKey))
            .freeze()
            .sign(TestConstants.privateKey)
    }

    private static func makeTransactionNft() throws -> TokenCreateTransaction {
        try TokenCreateTransaction()
            .nodeAccountIds([AccountId("0.0.5005"), AccountId("0.0.5006")])
            .transactionId(
                TransactionId(
                    accountId: 5006, validStart: Timestamp(seconds: 1_554_158_542, subSecondNanos: 0), scheduled: false)
            )
            .feeScheduleKey(.single(TestConstants.publicKey))
            .supplyKey(.single(TestConstants.publicKey))
            .maxSupply(500)
            .adminKey(.single(TestConstants.publicKey))
            .autoRenewAccountId(AccountId.fromString("0.0.123"))
            .autoRenewPeriod(Duration.seconds(100))
            .tokenSupplyType(TokenSupplyType.finite)
            .tokenType(TokenType.nonFungibleUnique)
            .freezeKey(.single(TestConstants.publicKey))
            .wipeKey(.single(TestConstants.publicKey))
            .symbol("F")
            .kycKey(.single(TestConstants.publicKey))
            .pauseKey(.single(TestConstants.publicKey))
            .expirationTime(Timestamp(seconds: 1_554_158_557, subSecondNanos: 0))
            .treasuryAccountId(AccountId.fromString("0.0.456"))
            .name("flook")
            .tokenMemo("flook memo")
            .metadata(TestConstants.metadata)
            .metadataKey(.single(TestConstants.publicKey))
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

    internal func test_Properties() throws {
        let tx = try Self.makeTransaction()

        XCTAssertEqual(tx.name, "flook")
        XCTAssertEqual(tx.symbol, "F")
        XCTAssertEqual(tx.decimals, 3)
        XCTAssertEqual(tx.initialSupply, 30)
        XCTAssertEqual(tx.treasuryAccountId, "0.0.456")
        XCTAssertEqual(tx.adminKey, .single(TestConstants.publicKey))
        XCTAssertEqual(tx.kycKey, .single(TestConstants.publicKey))
        XCTAssertEqual(tx.freezeKey, .single(TestConstants.publicKey))
        XCTAssertEqual(tx.wipeKey, .single(TestConstants.publicKey))
        XCTAssertEqual(tx.feeScheduleKey, .single(TestConstants.publicKey))
        XCTAssertEqual(tx.pauseKey, .single(TestConstants.publicKey))
        XCTAssertEqual(tx.freezeDefault, true)
        XCTAssertEqual(tx.expirationTime, Timestamp(seconds: 1_554_158_557, subSecondNanos: 0))
        XCTAssertEqual(tx.autoRenewAccountId, try AccountId.fromString("0.0.123"))
        XCTAssertEqual(tx.tokenMemo, "flook memo")
        XCTAssertEqual(tx.tokenType, TokenType.fungibleCommon)
        XCTAssertEqual(tx.tokenSupplyType, TokenSupplyType.infinite)
        XCTAssertEqual(tx.maxSupply, 0)
        XCTAssertEqual(tx.metadata, Data([3, 4]))
        XCTAssertEqual(tx.metadataKey, .single(TestConstants.publicKey))
    }
}
