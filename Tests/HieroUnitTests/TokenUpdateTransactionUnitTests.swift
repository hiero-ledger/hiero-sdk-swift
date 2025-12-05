// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import SwiftProtobuf
import XCTest

@testable import Hiero

internal final class TokenUpdateTransactionUnitTests: HieroUnitTestCase, TransactionTestable {
    typealias TransactionType = TokenUpdateTransaction

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
    private static let testExpirationTime = TestConstants.validStart

    static func makeTransaction() throws -> TokenUpdateTransaction {
        try TokenUpdateTransaction()
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .sign(TestConstants.privateKey)
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
            .metadata(TestConstants.metadata)
            .metadataKey(.single(TestConstants.publicKey))
            .freeze()
    }

    internal func test_Serialize() throws {
        try assertTransactionSerializes()
    }

    internal func test_ToFromBytes() throws {
        try assertTransactionRoundTrips()
    }

    internal func test_FromProtoBody() throws {
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
            proto.metadata = Google_Protobuf_BytesValue(TestConstants.metadata)
            proto.metadataKey = Self.testMetadataKey.publicKey.toProtobuf()
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.tokenUpdate = protoData
            proto.transactionID = TestConstants.transactionId.toProtobuf()
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

    internal func test_GetSetTokenId() {
        let tx = TokenUpdateTransaction()
        tx.tokenId(Self.testTokenId)

        XCTAssertEqual(tx.tokenId, Self.testTokenId)
    }

    internal func test_GetSetName() {
        let tx = TokenUpdateTransaction()
        tx.tokenName(Self.testTokenName)
        XCTAssertEqual(tx.tokenName, Self.testTokenName)
    }

    internal func test_GetSetSymbol() {
        let tx = TokenUpdateTransaction()
        tx.tokenSymbol(Self.testTokenSymbol)
        XCTAssertEqual(tx.tokenSymbol, Self.testTokenSymbol)
    }

    internal func test_GetSetTreasuryAccountId() {
        let tx = TokenUpdateTransaction()
        tx.treasuryAccountId(Self.testTreasuryAccountId)
        XCTAssertEqual(tx.treasuryAccountId, Self.testTreasuryAccountId)
    }

    internal func test_GetSetAdminKey() {
        let tx = TokenUpdateTransaction()
        tx.adminKey(.single(Self.testAdminKey.publicKey))
        XCTAssertEqual(tx.adminKey, .single(Self.testAdminKey.publicKey))
    }

    internal func test_GetSetKycKey() {
        let tx = TokenUpdateTransaction()
        tx.kycKey(.single(Self.testKycKey.publicKey))
        XCTAssertEqual(tx.kycKey, .single(Self.testKycKey.publicKey))
    }

    internal func test_GetSetFreezeKey() {
        let tx = TokenUpdateTransaction()
        tx.freezeKey(.single(Self.testFreezeKey.publicKey))
        XCTAssertEqual(tx.freezeKey, .single(Self.testFreezeKey.publicKey))
    }

    internal func test_GetSetWipeKey() {
        let tx = TokenUpdateTransaction()
        tx.wipeKey(.single(Self.testWipeKey.publicKey))
        XCTAssertEqual(tx.wipeKey, .single(Self.testWipeKey.publicKey))
    }

    internal func test_GetSetSupplyKey() {
        let tx = TokenUpdateTransaction()
        tx.supplyKey(.single(Self.testSupplyKey.publicKey))
        XCTAssertEqual(tx.supplyKey, .single(Self.testSupplyKey.publicKey))
    }

    internal func test_GetSetAutoRenewAccountId() {
        let tx = TokenUpdateTransaction()
        tx.autoRenewAccountId(Self.testAutoRenewAccountId)
        XCTAssertEqual(tx.autoRenewAccountId, Self.testAutoRenewAccountId)
    }

    internal func test_GetSetAutoRenewPeriod() {
        let tx = TokenUpdateTransaction()
        tx.autoRenewPeriod(Self.testAutoRenewPeriod)
        XCTAssertEqual(tx.autoRenewPeriod, Self.testAutoRenewPeriod)
    }

    internal func test_GetSetExpirationTime() {
        let tx = TokenUpdateTransaction()
        tx.expirationTime(Self.testExpirationTime)
        XCTAssertEqual(tx.expirationTime, Self.testExpirationTime)
    }

    internal func test_GetSetTokenMemo() {
        let tx = TokenUpdateTransaction()
        tx.tokenMemo(Self.testTokenMemo)
        XCTAssertEqual(tx.tokenMemo, Self.testTokenMemo)
    }

    internal func test_GetSetFeeScheduleKey() {
        let tx = TokenUpdateTransaction()
        tx.feeScheduleKey(.single(Self.testFeeScheduleKey.publicKey))
        XCTAssertEqual(tx.feeScheduleKey, .single(Self.testFeeScheduleKey.publicKey))
    }

    internal func test_GetSetPauseKey() {
        let tx = TokenUpdateTransaction()
        tx.pauseKey(.single(Self.testPauseKey.publicKey))
        XCTAssertEqual(tx.pauseKey, .single(Self.testPauseKey.publicKey))
    }

    internal func test_GetSetMetadata() {
        let tx = TokenUpdateTransaction()
        tx.metadata(TestConstants.metadata)
        XCTAssertEqual(tx.metadata, TestConstants.metadata)
    }

    internal func test_GetSetMetadataKey() {
        let tx = TokenUpdateTransaction()
        tx.metadataKey(.single(Self.testMetadataKey.publicKey))
        XCTAssertEqual(tx.metadataKey, .single(Self.testMetadataKey.publicKey))
    }
}
