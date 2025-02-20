/*
 * ‌
 * Hedera Swift SDK
 * ​
 * Copyright (C) 2023 - 2023 Hedera Hashgraph, LLC
 * ​
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ‍
 */

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class TokenCreateTransactionTests: XCTestCase {
    private static func createTransaction() throws -> TokenCreateTransaction {
        try TokenCreateTransaction()
            .nodeAccountIds([AccountId("0.0.5005"), AccountId("0.0.5006")])
            .transactionId(
                TransactionId(
                    accountId: 5005, validStart: Timestamp(seconds: 1_554_158_542, subSecondNanos: 0), scheduled: false)
            )
            .initialSupply(30)
            .feeScheduleKey(.single(Resources.publicKey))
            .supplyKey(.single(Resources.publicKey))
            .adminKey(.single(Resources.publicKey))
            .autoRenewAccountId(AccountId.fromString("0.0.123"))
            .autoRenewPeriod(Duration.seconds(100))
            .decimals(3)
            .freezeDefault(true)
            .freezeKey(.single(Resources.publicKey))
            .wipeKey(.single(Resources.publicKey))
            .symbol("F")
            .kycKey(.single(Resources.publicKey))
            .pauseKey(.single(Resources.publicKey))
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
            .metadata(Resources.metadata)
            .metadataKey(.single(Resources.publicKey))
            .freeze()
            .sign(Resources.privateKey)
    }

    private static func createTransactionNft() throws -> TokenCreateTransaction {
        try TokenCreateTransaction()
            .nodeAccountIds([AccountId("0.0.5005"), AccountId("0.0.5006")])
            .transactionId(
                TransactionId(
                    accountId: 5006, validStart: Timestamp(seconds: 1_554_158_542, subSecondNanos: 0), scheduled: false)
            )
            .feeScheduleKey(.single(Resources.publicKey))
            .supplyKey(.single(Resources.publicKey))
            .maxSupply(500)
            .adminKey(.single(Resources.publicKey))
            .autoRenewAccountId(AccountId.fromString("0.0.123"))
            .autoRenewPeriod(Duration.seconds(100))
            .tokenSupplyType(TokenSupplyType.finite)
            .tokenType(TokenType.nonFungibleUnique)
            .freezeKey(.single(Resources.publicKey))
            .wipeKey(.single(Resources.publicKey))
            .symbol("F")
            .kycKey(.single(Resources.publicKey))
            .pauseKey(.single(Resources.publicKey))
            .expirationTime(Timestamp(seconds: 1_554_158_557, subSecondNanos: 0))
            .treasuryAccountId(AccountId.fromString("0.0.456"))
            .name("flook")
            .tokenMemo("flook memo")
            .metadata(Resources.metadata)
            .metadataKey(.single(Resources.publicKey))
            .freeze()
            .sign(Resources.privateKey)
    }

    internal func testSerialize() throws {
        let tx = try Self.createTransaction().makeProtoBody()

        assertSnapshot(matching: tx, as: .description)
    }

    internal func testToFromBytes() throws {
        let tx = try Self.createTransaction()
        let tx2 = try Transaction.fromBytes(tx.toBytes())

        XCTAssertEqual(try tx.makeProtoBody(), try tx2.makeProtoBody())
    }

    internal func testSerializeNft() throws {
        let tx = try Self.createTransactionNft().makeProtoBody()

        assertSnapshot(matching: tx, as: .description)
    }

    internal func testToFromBytesNft() throws {
        let tx = try Self.createTransactionNft()
        let tx2 = try Transaction.fromBytes(tx.toBytes())

        XCTAssertEqual(try tx.makeProtoBody(), try tx2.makeProtoBody())
    }

    internal func testProperties() throws {
        let tx = try Self.createTransaction()

        XCTAssertEqual(tx.name, "flook")
        XCTAssertEqual(tx.symbol, "F")
        XCTAssertEqual(tx.decimals, 3)
        XCTAssertEqual(tx.initialSupply, 30)
        XCTAssertEqual(tx.treasuryAccountId, "0.0.456")
        XCTAssertEqual(tx.adminKey, .single(Resources.publicKey))
        XCTAssertEqual(tx.kycKey, .single(Resources.publicKey))
        XCTAssertEqual(tx.freezeKey, .single(Resources.publicKey))
        XCTAssertEqual(tx.wipeKey, .single(Resources.publicKey))
        XCTAssertEqual(tx.feeScheduleKey, .single(Resources.publicKey))
        XCTAssertEqual(tx.pauseKey, .single(Resources.publicKey))
        XCTAssertEqual(tx.freezeDefault, true)
        XCTAssertEqual(tx.expirationTime, Timestamp(seconds: 1_554_158_557, subSecondNanos: 0))
        XCTAssertEqual(tx.autoRenewAccountId, try AccountId.fromString("0.0.123"))
        XCTAssertEqual(tx.tokenMemo, "flook memo")
        XCTAssertEqual(tx.tokenType, TokenType.fungibleCommon)
        XCTAssertEqual(tx.tokenSupplyType, TokenSupplyType.infinite)
        XCTAssertEqual(tx.maxSupply, 0)
        XCTAssertEqual(tx.metadata, Data([3, 4]))
        XCTAssertEqual(tx.metadataKey, .single(Resources.publicKey))
    }
}
