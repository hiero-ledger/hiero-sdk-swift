/*
 * ‌
 * Hedera Swift SDK
 * ​
 * Copyright (C) 2022 - 2024 Hedera Hashgraph, LLC
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

internal class AccountCreateTransactionTests: XCTestCase {
    private static let testKey = Key.single(Resources.publicKey)
    private static let testMaxAutomaticTokenAssociations: Int32 = 101
    private static let testAutoRenewPeriod = Duration.hours(10)
    private static let testAutoRenewAccountId: AccountId = 30
    private static let testStakedAccountId: AccountId = 3
    private static let testStakedNodeId: UInt64 = 4
    private static let testAccountMemo = "fresh water"
    private static let testInitialBalance = Hbar.fromTinybars(1000)
    private static let testMaxTransactionFee = Hbar.fromTinybars(100_000)

    private static func makeTransaction() throws -> AccountCreateTransaction {
        let evmAddress = try EvmAddress.fromBytes("0x000000000000000000".data(using: .utf8)!)

        let tx = try AccountCreateTransaction()
            .nodeAccountIds(Resources.nodeAccountIds)
            .transactionId(Resources.txId)
            .key(testKey)
            .initialBalance(testInitialBalance)
            .accountMemo(testAccountMemo)
            .receiverSignatureRequired(true)
            .stakedAccountId(testStakedAccountId)
            .autoRenewPeriod(testAutoRenewPeriod)
            .autoRenewAccountId(testAutoRenewAccountId)
            .alias(evmAddress)
            .stakedNodeId(testStakedNodeId)
            .maxAutomaticTokenAssociations(testMaxAutomaticTokenAssociations)
            .maxTransactionFee(testMaxTransactionFee)
            .freeze()
            .sign(Resources.privateKey)

        return tx
    }

    private static func makeTransaction2() throws -> AccountCreateTransaction {
        try AccountCreateTransaction()
            .nodeAccountIds(Resources.nodeAccountIds)
            .transactionId(Resources.txId)
            .key(testKey)
            .initialBalance(testInitialBalance)
            .accountMemo(testAccountMemo)
            .receiverSignatureRequired(true)
            .stakedAccountId(testStakedAccountId)
            .autoRenewPeriod(testAutoRenewPeriod)
            .autoRenewAccountId(testAutoRenewAccountId)
            .stakedNodeId(testStakedNodeId)
            .maxAutomaticTokenAssociations(testMaxAutomaticTokenAssociations)
            .maxTransactionFee(testMaxTransactionFee)
            .freeze()
            .sign(Resources.privateKey)
    }

    internal func testSerialize() throws {
        let tx = try Self.makeTransaction().makeProtoBody()

        assertSnapshot(matching: tx, as: .description)
    }

    internal func testToFromBytes() throws {
        let tx = try Self.makeTransaction()
        let tx2 = try Transaction.fromBytes(tx.toBytes())

        XCTAssertEqual(try tx.makeProtoBody(), try tx2.makeProtoBody())
    }

    internal func testSerialize2() throws {
        let tx = try Self.makeTransaction2().makeProtoBody()

        assertSnapshot(matching: tx, as: .description)
    }

    internal func testToFromBytes2() throws {
        let tx = try Self.makeTransaction2()
        let tx2 = try Transaction.fromBytes(tx.toBytes())

        XCTAssertEqual(try tx.makeProtoBody(), try tx2.makeProtoBody())
    }

    internal func testProperties() throws {
        let tx = try Self.makeTransaction()

        XCTAssertEqual(tx.key, Self.testKey)
        XCTAssertEqual(tx.initialBalance, Self.testInitialBalance)
        XCTAssertEqual(tx.receiverSignatureRequired, true)
        XCTAssertEqual(tx.autoRenewPeriod, Self.testAutoRenewPeriod)
        XCTAssertEqual(tx.maxAutomaticTokenAssociations, Self.testMaxAutomaticTokenAssociations)
        XCTAssertEqual(tx.accountMemo, Self.testAccountMemo)
        XCTAssertEqual(tx.stakedAccountId, Self.testStakedAccountId)
        XCTAssertEqual(tx.stakedNodeId, Self.testStakedNodeId)
        XCTAssertEqual(tx.declineStakingReward, false)
        XCTAssertEqual(tx.alias, try EvmAddress.fromBytes("0x000000000000000000".data(using: .utf8)!))
    }

    internal func testFromProtoBody() throws {
        let protoData = Proto_CryptoCreateTransactionBody.with { proto in
            proto.alias = "0x000000000000000000".data(using: .utf8)!
            proto.autoRenewPeriod = Self.testAutoRenewPeriod.toProtobuf()
            proto.initialBalance = 1000
            proto.memo = Self.testAccountMemo
            proto.key = Self.testKey.toProtobuf()
            proto.stakedNodeID = Int64(Self.testStakedNodeId)
            proto.stakedAccountID = Self.testStakedAccountId.toProtobuf()
            proto.maxAutomaticTokenAssociations = Self.testMaxAutomaticTokenAssociations
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.cryptoCreateAccount = protoData
            proto.transactionID = Resources.txId.toProtobuf()
        }

        let tx = try AccountCreateTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.alias, try EvmAddress.fromBytes("0x000000000000000000".data(using: .utf8)!))
        XCTAssertEqual(tx.accountMemo, Self.testAccountMemo)
        XCTAssertEqual(tx.initialBalance, Self.testInitialBalance)
        XCTAssertEqual(tx.stakedAccountId, Self.testStakedAccountId)
        XCTAssertEqual(tx.autoRenewPeriod, Self.testAutoRenewPeriod)
        XCTAssertEqual(tx.maxAutomaticTokenAssociations, Self.testMaxAutomaticTokenAssociations)
    }

    internal func testGetSetKey() throws {
        let tx = AccountCreateTransaction()
        tx.key(Self.testKey)

        XCTAssertEqual(tx.key, Self.testKey)
    }

    internal func testGetSetInitialBalance() throws {
        let tx = AccountCreateTransaction()
        tx.initialBalance(Self.testInitialBalance)

        XCTAssertEqual(tx.initialBalance, Self.testInitialBalance)
    }

    internal func testGetSetAutoRenewPeriod() throws {
        let tx = AccountCreateTransaction()
        tx.autoRenewPeriod(Self.testAutoRenewPeriod)

        XCTAssertEqual(tx.autoRenewPeriod, Self.testAutoRenewPeriod)
    }

    internal func testGetSetAutoRenewAccountId() throws {
        let tx = AccountCreateTransaction()
        tx.autoRenewAccountId(Self.testAutoRenewAccountId)

        XCTAssertEqual(tx.autoRenewAccountId, Self.testAutoRenewAccountId)
    }

    internal func testGetSetAccountMemo() throws {
        let tx = AccountCreateTransaction()
        tx.accountMemo(Self.testAccountMemo)

        XCTAssertEqual(tx.accountMemo, Self.testAccountMemo)
    }

    internal func testGetSetAlias() throws {
        let tx = AccountCreateTransaction()
        tx.alias(try EvmAddress.fromBytes("0x000000000000000000".data(using: .utf8)!))

        XCTAssertEqual(tx.alias, try EvmAddress.fromBytes("0x000000000000000000".data(using: .utf8)!))
    }

    internal func testGetSetStakedAccountId() throws {
        let tx = AccountCreateTransaction()
        tx.stakedAccountId(Self.testStakedAccountId)

        XCTAssertEqual(tx.stakedAccountId, Self.testStakedAccountId)
    }
}
