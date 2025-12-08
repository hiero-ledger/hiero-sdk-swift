// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class TokenFeeScheduleUpdateTransactionUnitTests: HieroUnitTestCase, TransactionTestable {
    typealias TransactionType = TokenFeeScheduleUpdateTransaction

    private static let testTokenId: TokenId = 4322
    private static let testCustomFees: [AnyCustomFee] = [
        .fixed(.init(amount: 10, denominatingTokenId: 483902, feeCollectorAccountId: 4322)),
        .fractional(.init(amount: "3/7", minimumAmount: 3, maximumAmount: 100, feeCollectorAccountId: 389042)),
    ]

    static func makeTransaction() throws -> TokenFeeScheduleUpdateTransaction {
        try TokenFeeScheduleUpdateTransaction()
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .sign(TestConstants.privateKey)
            .tokenId(testTokenId)
            .customFees(testCustomFees)
            .freeze()
    }

    internal func test_Serialize() throws {
        try assertTransactionSerializes()
    }

    internal func test_ToFromBytes() throws {
        try assertTransactionRoundTrips()
    }

    internal func test_FromProtoBody() throws {
        let protoData = Proto_TokenFeeScheduleUpdateTransactionBody.with { proto in
            proto.tokenID = Self.testTokenId.toProtobuf()
            proto.customFees = Self.testCustomFees.toProtobuf()
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.tokenFeeScheduleUpdate = protoData
            proto.transactionID = TestConstants.transactionId.toProtobuf()
        }

        let tx = try TokenFeeScheduleUpdateTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.tokenId, Self.testTokenId)
        XCTAssertEqual(tx.customFees, Self.testCustomFees)
    }

    internal func test_GetSetTokenId() {
        let tx = TokenFeeScheduleUpdateTransaction()
        tx.tokenId(Self.testTokenId)

        XCTAssertEqual(tx.tokenId, Self.testTokenId)
    }

    internal func test_GetSetCustomFees() {
        let tx = TokenFeeScheduleUpdateTransaction()
        tx.customFees(Self.testCustomFees)

        XCTAssertEqual(tx.customFees, Self.testCustomFees)
    }
}
