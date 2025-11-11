// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class ContractUpdateTransactionTests: XCTestCase {
    private static let contractId: ContractId = "0.0.5007"
    private static let adminKey = Key.single(Resources.publicKey)
    private static let maxAutomaticTokenAssociations: Int32 = 101
    private static let autoRenewPeriod = Duration.days(1)
    private static let contractMemo = "3"
    private static let expirationTime = Timestamp(seconds: 1_554_158_543, subSecondNanos: 0)
    private static let proxyAccountId = AccountId(4)
    private static let autoRenewAccountId = AccountId(30)
    private static let stakedAccountId: AccountId = "0.0.3"
    private static let stakedNodeId: Int64 = 4

    private static func updateTransaction() throws -> ContractUpdateTransaction {
        try ContractUpdateTransaction()
            .nodeAccountIds(Resources.nodeAccountIds)
            .transactionId(Resources.txId)
            .sign(Resources.privateKey)
            .contractId(contractId)
            .adminKey(adminKey)
            .maxAutomaticTokenAssociations(maxAutomaticTokenAssociations)
            .autoRenewPeriod(autoRenewPeriod)
            .contractMemo(contractMemo)
            .expirationTime(expirationTime)
            .proxyAccountId(proxyAccountId)
            .autoRenewAccountId(autoRenewAccountId)
            .stakedAccountId(stakedAccountId)
            .maxTransactionFee(.fromTinybars(100_000))
            .freeze()
    }

    private static func updateTransaction2() throws -> ContractUpdateTransaction {
        try ContractUpdateTransaction()
            .nodeAccountIds(Resources.nodeAccountIds)
            .transactionId(Resources.txId)
            .sign(Resources.privateKey)
            .contractId(contractId)
            .adminKey(adminKey)
            .maxAutomaticTokenAssociations(maxAutomaticTokenAssociations)
            .autoRenewPeriod(autoRenewPeriod)
            .contractMemo(contractMemo)
            .expirationTime(expirationTime)
            .proxyAccountId(proxyAccountId)
            .autoRenewAccountId(autoRenewAccountId)
            .stakedNodeId(stakedNodeId)
            .maxTransactionFee(.fromTinybars(100_000))
            .freeze()
    }

    internal func testSerialize() throws {
        let tx = try Self.updateTransaction().toProtobuf()

        assertSnapshot(of: tx, as: .description)
    }

    internal func testSerialize2() throws {
        let tx = try Self.updateTransaction2().toProtobuf()

        assertSnapshot(of: tx, as: .description)
    }

    internal func testToFromBytes() throws {
        let tx = try Self.updateTransaction()
        let tx2 = try Transaction.fromBytes(tx.toBytes())

        XCTAssertEqual(try tx.makeProtoBody(), try tx2.makeProtoBody())
    }

    internal func testToFromBytes2() throws {
        let tx = try Self.updateTransaction2()
        let tx2 = try Transaction.fromBytes(tx.toBytes())

        XCTAssertEqual(try tx.makeProtoBody(), try tx2.makeProtoBody())
    }

    internal func testFromProtoBody() throws {
        let protoData = Proto_ContractUpdateTransactionBody.with { proto in
            proto.contractID = Self.contractId.toProtobuf()
            proto.adminKey = Self.adminKey.toProtobuf()
            proto.maxAutomaticTokenAssociations = .init(Self.maxAutomaticTokenAssociations)
            proto.autoRenewPeriod = Self.autoRenewPeriod.toProtobuf()
            proto.memoWrapper = .init(Self.contractMemo)
            proto.expirationTime = Self.expirationTime.toProtobuf()
            proto.proxyAccountID = Self.proxyAccountId.toProtobuf()
            proto.autoRenewAccountID = Self.autoRenewAccountId.toProtobuf()
            proto.stakedID = .stakedAccountID(Self.stakedAccountId.toProtobuf())
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.contractUpdateInstance = protoData
            proto.transactionID = Resources.txId.toProtobuf()
        }

        let tx = try ContractUpdateTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.contractId, Self.contractId)
        XCTAssertEqual(tx.adminKey, Self.adminKey)
        XCTAssertEqual(tx.maxAutomaticTokenAssociations, Self.maxAutomaticTokenAssociations)
        XCTAssertEqual(tx.autoRenewPeriod, Self.autoRenewPeriod)
        XCTAssertEqual(tx.contractMemo, Self.contractMemo)
        XCTAssertEqual(tx.expirationTime, Self.expirationTime)
        XCTAssertEqual(tx.proxyAccountId, Self.proxyAccountId)
        XCTAssertEqual(tx.autoRenewAccountId, Self.autoRenewAccountId)
        XCTAssertEqual(tx.stakedAccountId, Self.stakedAccountId)
        XCTAssertEqual(tx.stakedNodeId, nil)
    }

    internal func testGetSetContractId() {
        let tx = ContractUpdateTransaction()
        tx.contractId(Self.contractId)

        XCTAssertEqual(tx.contractId, Self.contractId)
    }

    internal func testGetSetAdminKey() {
        let tx = ContractUpdateTransaction()
        tx.adminKey(Self.adminKey)

        XCTAssertEqual(tx.adminKey, Self.adminKey)
    }

    internal func testGetSetMaxAutomaticTokenAssociations() {
        let tx = ContractUpdateTransaction()
        tx.maxAutomaticTokenAssociations(Self.maxAutomaticTokenAssociations)

        XCTAssertEqual(tx.maxAutomaticTokenAssociations, Self.maxAutomaticTokenAssociations)
    }

    internal func testGetSetAutoRenewPeriod() {
        let tx = ContractUpdateTransaction()
        tx.autoRenewPeriod(Self.autoRenewPeriod)

        XCTAssertEqual(tx.autoRenewPeriod, Self.autoRenewPeriod)
    }

    internal func testGetSetContractMemo() {
        let tx = ContractUpdateTransaction()
        tx.contractMemo(Self.contractMemo)

        XCTAssertEqual(tx.contractMemo, Self.contractMemo)
    }

    internal func testGetSetExpirationTime() {
        let tx = ContractUpdateTransaction()
        tx.expirationTime(Self.expirationTime)

        XCTAssertEqual(tx.expirationTime, Self.expirationTime)
    }

    internal func testGetSetProxyAccountId() {
        let tx = ContractUpdateTransaction()
        tx.proxyAccountId(Self.proxyAccountId)

        XCTAssertEqual(tx.proxyAccountId, Self.proxyAccountId)
    }

    internal func testGetSetAutoRenewAccountId() {
        let tx = ContractUpdateTransaction()
        tx.autoRenewAccountId(Self.autoRenewAccountId)

        XCTAssertEqual(tx.autoRenewAccountId, Self.autoRenewAccountId)
    }

    internal func testGetSetStakedAccountId() {
        let tx = ContractUpdateTransaction()
        tx.stakedAccountId(Self.stakedAccountId)

        XCTAssertEqual(tx.stakedAccountId, Self.stakedAccountId)
    }

    internal func testGetSetStakedNodeId() {
        let tx = ContractUpdateTransaction()
        tx.stakedNodeId(Self.stakedNodeId)

        XCTAssertEqual(tx.stakedNodeId, Self.stakedNodeId)
    }
}
