// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class ContractCreateTransactionUnitTests: HieroUnitTestCase, TransactionTestable {
    typealias TransactionType = ContractCreateTransaction

    private static let bytecodeFileId: FileId = 3003
    private static let adminKey = Key.single(TestConstants.publicKey)
    private static let gas: UInt64 = 0
    private static let initialBalance = Hbar.fromTinybars(1000)
    private static let maxAutomaticTokenAssociations: Int32 = 101
    private static let autoRenewPeriod = Duration.hours(10)
    private static let constructorParameters = Data([10, 11, 12, 13, 25])
    private static let autoRenewAccountId: AccountId = 30
    private static let stakedAccountId: AccountId = 3
    private static let stakedNodeId: UInt64 = 4

    static func makeTransaction() throws -> ContractCreateTransaction {
        try ContractCreateTransaction()
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .sign(TestConstants.privateKey)
            .bytecodeFileId(bytecodeFileId)
            .adminKey(adminKey)
            .gas(gas)
            .initialBalance(initialBalance)
            .maxAutomaticTokenAssociations(maxAutomaticTokenAssociations)
            .autoRenewPeriod(autoRenewPeriod)
            .constructorParameters(constructorParameters)
            .autoRenewAccountId(autoRenewAccountId)
            .stakedAccountId(stakedAccountId)
            .maxTransactionFee(.fromTinybars(100_000))
            .freeze()
    }

    private static func makeTransaction2() throws -> ContractCreateTransaction {
        try ContractCreateTransaction()
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .sign(TestConstants.privateKey)
            .bytecodeFileId(bytecodeFileId)
            .adminKey(adminKey)
            .gas(gas)
            .initialBalance(initialBalance)
            .maxAutomaticTokenAssociations(maxAutomaticTokenAssociations)
            .autoRenewPeriod(autoRenewPeriod)
            .constructorParameters(constructorParameters)
            .autoRenewAccountId(autoRenewAccountId)
            .stakedNodeId(stakedNodeId)
            .maxTransactionFee(.fromTinybars(100_000))
            .freeze()
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

    internal func test_FromProtoBody() throws {
        let protoData = Proto_ContractCreateTransactionBody.with { proto in
            proto.fileID = Self.bytecodeFileId.toProtobuf()
            proto.adminKey = Self.adminKey.toProtobuf()
            proto.gas = Int64(Self.gas)
            proto.initialBalance = Self.initialBalance.toTinybars()
            proto.maxAutomaticTokenAssociations = Self.maxAutomaticTokenAssociations
            proto.autoRenewPeriod = Self.autoRenewPeriod.toProtobuf()
            proto.constructorParameters = Self.constructorParameters
            proto.autoRenewAccountID = Self.autoRenewAccountId.toProtobuf()
            proto.stakedAccountID = Self.stakedAccountId.toProtobuf()
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.contractCreateInstance = protoData
            proto.transactionID = TestConstants.transactionId.toProtobuf()
        }

        let tx = try ContractCreateTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.bytecodeFileId, Self.bytecodeFileId)
        XCTAssertEqual(tx.adminKey, Self.adminKey)
        XCTAssertEqual(tx.gas, Self.gas)
        XCTAssertEqual(tx.initialBalance, Self.initialBalance)
        XCTAssertEqual(tx.maxAutomaticTokenAssociations, Self.maxAutomaticTokenAssociations)
        XCTAssertEqual(tx.autoRenewPeriod, Self.autoRenewPeriod)
        XCTAssertEqual(tx.constructorParameters, Self.constructorParameters)
        XCTAssertEqual(tx.autoRenewAccountId, Self.autoRenewAccountId)
        XCTAssertEqual(tx.stakedAccountId, Self.stakedAccountId)
        XCTAssertEqual(tx.stakedNodeId, nil)
    }

    internal func test_GetSetBytecodeFileId() {
        let tx = ContractCreateTransaction()
        tx.bytecodeFileId(Self.bytecodeFileId)

        XCTAssertEqual(tx.bytecodeFileId, Self.bytecodeFileId)
    }

    internal func test_GetSetAdminKey() {
        let tx = ContractCreateTransaction()
        tx.adminKey(Self.adminKey)

        XCTAssertEqual(tx.adminKey, Self.adminKey)
    }

    internal func test_GetSetGas() {
        let tx = ContractCreateTransaction()
        tx.gas(Self.gas)

        XCTAssertEqual(tx.gas, Self.gas)
    }

    internal func test_GetSetInitialBalance() {
        let tx = ContractCreateTransaction()
        tx.initialBalance(Self.initialBalance)

        XCTAssertEqual(tx.initialBalance, Self.initialBalance)
    }

    internal func test_GetSetMaxAutomaticTokenAssociations() {
        let tx = ContractCreateTransaction()
        tx.maxAutomaticTokenAssociations(Self.maxAutomaticTokenAssociations)

        XCTAssertEqual(tx.maxAutomaticTokenAssociations, Self.maxAutomaticTokenAssociations)
    }

    internal func test_GetSetAutoRenewPeriod() {
        let tx = ContractCreateTransaction()
        tx.autoRenewPeriod(Self.autoRenewPeriod)

        XCTAssertEqual(tx.autoRenewPeriod, Self.autoRenewPeriod)
    }

    internal func test_GetSetConstructorParameters() {
        let tx = ContractCreateTransaction()
        tx.constructorParameters(Self.constructorParameters)

        XCTAssertEqual(tx.constructorParameters, Self.constructorParameters)
    }

    internal func test_GetSetAutoRenewAccountId() {
        let tx = ContractCreateTransaction()
        tx.autoRenewAccountId(Self.autoRenewAccountId)

        XCTAssertEqual(tx.autoRenewAccountId, Self.autoRenewAccountId)
    }

    internal func test_GetSetStakedAccountId() {
        let tx = ContractCreateTransaction()
        tx.stakedAccountId(Self.stakedAccountId)

        XCTAssertEqual(tx.stakedAccountId, Self.stakedAccountId)
    }

    internal func test_GetSetStakedNodeId() {
        let tx = ContractCreateTransaction()
        tx.stakedNodeId(Self.stakedNodeId)

        XCTAssertEqual(tx.stakedNodeId, Self.stakedNodeId)
    }
}
