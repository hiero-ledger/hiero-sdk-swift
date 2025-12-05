// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class AccountCreateTransactionUnitTests: HieroUnitTestCase, TransactionTestable {
    typealias TransactionType = AccountCreateTransaction

    private static let testKeyEd25519 = Key.single(TestConstants.publicKey)
    private static let testMaxAutomaticTokenAssociations: Int32 = 101
    private static let testAutoRenewPeriod = Duration.hours(10)
    private static let testAutoRenewAccountId: AccountId = 30
    private static let testStakedAccountId: AccountId = 3
    private static let testStakedNodeId: UInt64 = 4
    private static let testAccountMemo = "fresh water"
    private static let testInitialBalance = Hbar.fromTinybars(1000)
    private static let testMaxTransactionFee = Hbar.fromTinybars(100_000)
    private static let testKeyEcdsa = try! PrivateKey.fromStringEcdsa(
        "7f109a9e3b0d8ecfba9cc23a3614433ce0fa7ddcc80f2a8f10b222179a5a80d6")
    private static let testAliasEVMString = "0x5c562e90feaf0eebd33ea75d21024f249d451417"

    static func makeTransaction() throws -> AccountCreateTransaction {
        let tx = try AccountCreateTransaction()
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .keyWithAlias(testKeyEcdsa)
            .keyWithAlias(testKeyEd25519, testKeyEcdsa)
            .keyWithoutAlias(testKeyEd25519)
            .initialBalance(testInitialBalance)
            .accountMemo(testAccountMemo)
            .receiverSignatureRequired(true)
            .stakedAccountId(testStakedAccountId)
            .autoRenewPeriod(testAutoRenewPeriod)
            .autoRenewAccountId(testAutoRenewAccountId)
            .alias(testAliasEVMString)
            .stakedNodeId(testStakedNodeId)
            .maxAutomaticTokenAssociations(testMaxAutomaticTokenAssociations)
            .maxTransactionFee(testMaxTransactionFee)
            .freeze()
            .sign(TestConstants.privateKey)

        return tx
    }

    private static func makeTransaction2() throws -> AccountCreateTransaction {
        try AccountCreateTransaction()
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .keyWithAlias(testKeyEcdsa)
            .keyWithAlias(testKeyEd25519, testKeyEcdsa)
            .keyWithoutAlias(testKeyEd25519)
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
            .sign(TestConstants.privateKey)
    }

    internal func test_Serialize() throws {
        try assertTransactionSerializes()
    }

    internal func test_ToFromBytes() throws {
        try assertTransactionRoundTrips()
    }

    internal func test_Serialize2() throws {
        let tx = try Self.makeTransaction2().makeProtoBody()

        SnapshotTesting.assertSnapshot(of: tx, as: .description)
    }

    internal func test_ToFromBytes2() throws {
        let tx = try Self.makeTransaction2()
        let tx2 = try Transaction.fromBytes(tx.toBytes())

        XCTAssertEqual(try tx.makeProtoBody(), try tx2.makeProtoBody())
    }

    internal func test_Properties() throws {
        let tx = try Self.makeTransaction()

        XCTAssertEqual(tx.key, Self.testKeyEd25519)
        XCTAssertEqual(tx.initialBalance, Self.testInitialBalance)
        XCTAssertEqual(tx.receiverSignatureRequired, true)
        XCTAssertEqual(tx.autoRenewPeriod, Self.testAutoRenewPeriod)
        XCTAssertEqual(tx.maxAutomaticTokenAssociations, Self.testMaxAutomaticTokenAssociations)
        XCTAssertEqual(tx.accountMemo, Self.testAccountMemo)
        XCTAssertEqual(tx.stakedAccountId, Self.testStakedAccountId)
        XCTAssertEqual(tx.stakedNodeId, Self.testStakedNodeId)
        XCTAssertEqual(tx.declineStakingReward, false)
        XCTAssertEqual(tx.alias, try EvmAddress.fromString("0x5c562e90feaf0eebd33ea75d21024f249d451417"))
    }

    internal func test_FromProtoBody() throws {
        let protoData = Proto_CryptoCreateTransactionBody.with { proto in
            proto.alias = try! EvmAddress.fromString(Self.testAliasEVMString).data
            proto.autoRenewPeriod = Self.testAutoRenewPeriod.toProtobuf()
            proto.initialBalance = 1000
            proto.memo = Self.testAccountMemo
            proto.key = Self.testKeyEd25519.toProtobuf()
            proto.stakedNodeID = Int64(Self.testStakedNodeId)
            proto.stakedAccountID = Self.testStakedAccountId.toProtobuf()
            proto.maxAutomaticTokenAssociations = Self.testMaxAutomaticTokenAssociations
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.cryptoCreateAccount = protoData
            proto.transactionID = TestConstants.transactionId.toProtobuf()
        }

        let tx = try AccountCreateTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.alias, try EvmAddress.fromString("0x5c562e90feaf0eebd33ea75d21024f249d451417"))
        XCTAssertEqual(tx.accountMemo, Self.testAccountMemo)
        XCTAssertEqual(tx.initialBalance, Self.testInitialBalance)
        XCTAssertEqual(tx.stakedAccountId, Self.testStakedAccountId)
        XCTAssertEqual(tx.autoRenewPeriod, Self.testAutoRenewPeriod)
        XCTAssertEqual(tx.maxAutomaticTokenAssociations, Self.testMaxAutomaticTokenAssociations)
    }

    internal func test_GetSetKey() throws {
        let tx = AccountCreateTransaction()
        tx.keyWithoutAlias(Self.testKeyEd25519)

        XCTAssertEqual(tx.key, Self.testKeyEd25519)
    }

    internal func test_GetSetInitialBalance() throws {
        let tx = AccountCreateTransaction()
        tx.initialBalance(Self.testInitialBalance)

        XCTAssertEqual(tx.initialBalance, Self.testInitialBalance)
    }

    internal func test_GetSetAutoRenewPeriod() throws {
        let tx = AccountCreateTransaction()
        tx.autoRenewPeriod(Self.testAutoRenewPeriod)

        XCTAssertEqual(tx.autoRenewPeriod, Self.testAutoRenewPeriod)
    }

    internal func test_GetSetAutoRenewAccountId() throws {
        let tx = AccountCreateTransaction()
        tx.autoRenewAccountId(Self.testAutoRenewAccountId)

        XCTAssertEqual(tx.autoRenewAccountId, Self.testAutoRenewAccountId)
    }

    internal func test_GetSetAccountMemo() throws {
        let tx = AccountCreateTransaction()
        tx.accountMemo(Self.testAccountMemo)

        XCTAssertEqual(tx.accountMemo, Self.testAccountMemo)
    }

    internal func test_GetSetAlias() throws {
        let tx = AccountCreateTransaction()
        tx.alias(try EvmAddress.fromBytes("0x000000000000000000".data(using: .utf8)!))

        XCTAssertEqual(tx.alias, try EvmAddress.fromBytes("0x000000000000000000".data(using: .utf8)!))
    }

    internal func test_GetSetStakedAccountId() throws {
        let tx = AccountCreateTransaction()
        tx.stakedAccountId(Self.testStakedAccountId)

        XCTAssertEqual(tx.stakedAccountId, Self.testStakedAccountId)
    }
}
