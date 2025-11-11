// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import SwiftProtobuf
import XCTest

@testable import Hiero

internal final class TokenUpdateTransactionTests: XCTestCase {
    private static let testAdminKey: PrivateKey =
        "302e020100300506032b657004220420db484b828e64b2d8f12ce3c0a0e93a0b8cce7af1bb8f39c97732394482538e11"
    private static let testKycKey: PrivateKey =
        "302e020100300506032b657004220420db484b828e64b2d8f12ce3c0a0e93a0b8cce7af1bb8f39c97732394482538e12"
    private static let testFreezeKey: PrivateKey =
        "302e020100300506032b657004220420db484b828e64b2d8f12ce3c0a0e93a0b8cce7af1bb8f39c97732394482538e13"
    private static let testWipeKey: PrivateKey =
        "302e020100300506032b657004220420db484b828e64b2d8f12ce3c0a0e93a0b8cce7af1bb8f39c97732394482538e14"
    private static let testSupplyKey: PrivateKey =
        "302e020100300506032b657004220420db484b828e64b2d8f12ce3c0a0e93a0b8cce7af1bb8f39c97732394482538e16"
    private static let testFeeScheduleKey: PrivateKey =
        "302e020100300506032b657004220420db484b828e64b2d8f12ce3c0a0e93a0b8cce7af1bb8f39c97732394482538e11"
    private static let testPauseKey: PrivateKey =
        "302e020100300506032b657004220420db484b828e64b2d8f12ce3c0a0e93a0b8cce7af1bb8f39c97732394482538e11"
    private static let testMetadataKey: PrivateKey =
        "302e020100300506032b657004220420db484b828e64b2d8f12ce3c0a0e93a0b8cce7af1bb8f39c97732394482538e18"

    private static let testTreasuryAccountId: AccountId = "7.7.7"
    private static let testAutoRenewAccountId: AccountId = "8.8.8"
    private static let testTokenName: String = "test name"
    private static let testTokenSymbol: String = "test symbol"
    private static let testTokenMemo: String = "test memo"
    private static let testTokenId: TokenId = "4.2.0"
    private static let testAutoRenewPeriod: Duration = .hours(10)
    private static let testExpirationTime = Resources.validStart

    private static func makeTransaction() throws -> TokenUpdateTransaction {
        try TokenUpdateTransaction()
            .nodeAccountIds(Resources.nodeAccountIds)
            .transactionId(Resources.txId)
            .sign(Resources.privateKey)
            .tokenId(testTokenId)
            .supplyKey(.single(testSupplyKey.publicKey))
            .adminKey(.single(testSupplyKey.publicKey))
            .autoRenewAccountId(testAutoRenewAccountId)
            .autoRenewPeriod(testAutoRenewPeriod)
            .freezeKey(.single(testFreezeKey.publicKey))
            .wipeKey(.single(testWipeKey.publicKey))
            .tokenSymbol(testTokenSymbol)
            .kycKey(.single(testKycKey.publicKey))
            .pauseKey(.single(testPauseKey.publicKey))
            .expirationTime(testExpirationTime)
            .treasuryAccountId(testTreasuryAccountId)
            .tokenName(testTokenName)
            .tokenMemo(testTokenMemo)
            .metadata(Resources.metadata)
            .metadataKey(.single(Resources.publicKey))
            .freeze()
    }

    internal func testSerialize() throws {
        let tx = try Self.makeTransaction().makeProtoBody()

        assertSnapshot(of: tx, as: .description)
    }

    internal func testToFromBytes() throws {
        let tx = try Self.makeTransaction()

        let tx2 = try Transaction.fromBytes(tx.toBytes())

        XCTAssertEqual(try tx.makeProtoBody(), try tx2.makeProtoBody())
    }

    internal func testFromProtoBody() throws {
        let protoData = Proto_TokenUpdateTransactionBody.with { proto in
            proto.token = Self.testTokenId.toProtobuf()
            proto.symbol = Self.testTokenSymbol
            proto.name = Self.testTokenName
            proto.treasury = Self.testTreasuryAccountId.toProtobuf()
            proto.adminKey = Self.testAdminKey.publicKey.toProtobuf()
            proto.kycKey = Self.testKycKey.publicKey.toProtobuf()
            proto.freezeKey = Self.testFreezeKey.publicKey.toProtobuf()
            proto.wipeKey = Self.testWipeKey.publicKey.toProtobuf()
            proto.supplyKey = Self.testSupplyKey.publicKey.toProtobuf()
            proto.autoRenewAccount = Self.testAutoRenewAccountId.toProtobuf()
            proto.autoRenewPeriod = Self.testAutoRenewPeriod.toProtobuf()
            proto.expiry = Self.testExpirationTime.toProtobuf()
            proto.memo = .with { $0.value = Self.testTokenMemo }
            proto.feeScheduleKey = Self.testFeeScheduleKey.publicKey.toProtobuf()
            proto.pauseKey = Self.testPauseKey.publicKey.toProtobuf()
            proto.metadata = Google_Protobuf_BytesValue(Resources.metadata)
            proto.metadataKey = Self.testMetadataKey.publicKey.toProtobuf()
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.tokenUpdate = protoData
            proto.transactionID = Resources.txId.toProtobuf()
        }

        let tx = try TokenUpdateTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.tokenId, Self.testTokenId)
        XCTAssertEqual(tx.tokenName, Self.testTokenName)
        XCTAssertEqual(tx.tokenSymbol, Self.testTokenSymbol)
        XCTAssertEqual(tx.treasuryAccountId, Self.testTreasuryAccountId)
        XCTAssertEqual(tx.adminKey, .single(Self.testAdminKey.publicKey))
        XCTAssertEqual(tx.kycKey, .single(Self.testKycKey.publicKey))
        XCTAssertEqual(tx.freezeKey, .single(Self.testFreezeKey.publicKey))
        XCTAssertEqual(tx.wipeKey, .single(Self.testWipeKey.publicKey))
        XCTAssertEqual(tx.supplyKey, .single(Self.testSupplyKey.publicKey))
        XCTAssertEqual(tx.autoRenewAccountId, Self.testAutoRenewAccountId)
        XCTAssertEqual(tx.autoRenewPeriod, Self.testAutoRenewPeriod)
        XCTAssertEqual(tx.expirationTime, Self.testExpirationTime)
        XCTAssertEqual(tx.tokenMemo, Self.testTokenMemo)
        XCTAssertEqual(tx.feeScheduleKey, .single(Self.testFeeScheduleKey.publicKey))
        XCTAssertEqual(tx.pauseKey, .single(Self.testPauseKey.publicKey))
        XCTAssertEqual(tx.metadata, Data([3, 4]))
        XCTAssertEqual(tx.metadataKey, .single(Self.testMetadataKey.publicKey))
    }

    internal func testGetSetTokenId() {
        let tx = TokenUpdateTransaction()
        tx.tokenId(Self.testTokenId)

        XCTAssertEqual(tx.tokenId, Self.testTokenId)
    }

    internal func testGetSetName() {
        let tx = TokenUpdateTransaction()
        tx.tokenName(Self.testTokenName)
        XCTAssertEqual(tx.tokenName, Self.testTokenName)
    }

    internal func testGetSetSymbol() {
        let tx = TokenUpdateTransaction()
        tx.tokenSymbol(Self.testTokenSymbol)
        XCTAssertEqual(tx.tokenSymbol, Self.testTokenSymbol)
    }

    internal func testGetSetTreasuryAccountId() {
        let tx = TokenUpdateTransaction()
        tx.treasuryAccountId(Self.testTreasuryAccountId)
        XCTAssertEqual(tx.treasuryAccountId, Self.testTreasuryAccountId)
    }

    internal func testGetSetAdminKey() {
        let tx = TokenUpdateTransaction()
        tx.adminKey(.single(Self.testAdminKey.publicKey))
        XCTAssertEqual(tx.adminKey, .single(Self.testAdminKey.publicKey))
    }

    internal func testGetSetKycKey() {
        let tx = TokenUpdateTransaction()
        tx.kycKey(.single(Self.testKycKey.publicKey))
        XCTAssertEqual(tx.kycKey, .single(Self.testKycKey.publicKey))
    }

    internal func testGetSetFreezeKey() {
        let tx = TokenUpdateTransaction()
        tx.freezeKey(.single(Self.testFreezeKey.publicKey))
        XCTAssertEqual(tx.freezeKey, .single(Self.testFreezeKey.publicKey))
    }

    internal func testGetSetWipeKey() {
        let tx = TokenUpdateTransaction()
        tx.wipeKey(.single(Self.testWipeKey.publicKey))
        XCTAssertEqual(tx.wipeKey, .single(Self.testWipeKey.publicKey))
    }

    internal func testGetSetSupplyKey() {
        let tx = TokenUpdateTransaction()
        tx.supplyKey(.single(Self.testSupplyKey.publicKey))
        XCTAssertEqual(tx.supplyKey, .single(Self.testSupplyKey.publicKey))
    }

    internal func testGetSetAutoRenewAccountId() {
        let tx = TokenUpdateTransaction()
        tx.autoRenewAccountId(Self.testAutoRenewAccountId)
        XCTAssertEqual(tx.autoRenewAccountId, Self.testAutoRenewAccountId)
    }

    internal func testGetSetAutoRenewPeriod() {
        let tx = TokenUpdateTransaction()
        tx.autoRenewPeriod(Self.testAutoRenewPeriod)
        XCTAssertEqual(tx.autoRenewPeriod, Self.testAutoRenewPeriod)
    }

    internal func testGetSetExpirationTime() {
        let tx = TokenUpdateTransaction()
        tx.expirationTime(Self.testExpirationTime)
        XCTAssertEqual(tx.expirationTime, Self.testExpirationTime)
    }

    internal func testGetSetTokenMemo() {
        let tx = TokenUpdateTransaction()
        tx.tokenMemo(Self.testTokenMemo)
        XCTAssertEqual(tx.tokenMemo, Self.testTokenMemo)
    }

    internal func testGetSetFeeScheduleKey() {
        let tx = TokenUpdateTransaction()
        tx.feeScheduleKey(.single(Self.testFeeScheduleKey.publicKey))
        XCTAssertEqual(tx.feeScheduleKey, .single(Self.testFeeScheduleKey.publicKey))
    }

    internal func testGetSetPauseKey() {
        let tx = TokenUpdateTransaction()
        tx.pauseKey(.single(Self.testPauseKey.publicKey))
        XCTAssertEqual(tx.pauseKey, .single(Self.testPauseKey.publicKey))
    }

    internal func testGetSetMetadata() {
        let tx = TokenUpdateTransaction()
        tx.metadata(Resources.metadata)
        XCTAssertEqual(tx.metadata, Resources.metadata)
    }

    internal func testGetSetMetadataKey() {
        let tx = TokenUpdateTransaction()
        tx.metadataKey(.single(Self.testMetadataKey.publicKey))
        XCTAssertEqual(tx.metadataKey, .single(Self.testMetadataKey.publicKey))
    }
}
