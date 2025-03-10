// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class TokenFeeScheduleUpdateTransactionTests: XCTestCase {
    private static let testTokenId: TokenId = 4322
    private static let testCustomFees: [AnyCustomFee] = [
        .fixed(.init(amount: 10, denominatingTokenId: 483902, feeCollectorAccountId: 4322)),
        .fractional(.init(amount: "3/7", minimumAmount: 3, maximumAmount: 100, feeCollectorAccountId: 389042)),
    ]

    private static func makeTransaction() throws -> TokenFeeScheduleUpdateTransaction {
        try TokenFeeScheduleUpdateTransaction()
            .nodeAccountIds(Resources.nodeAccountIds)
            .transactionId(Resources.txId)
            .sign(Resources.privateKey)
            .tokenId(testTokenId)
            .customFees(testCustomFees)
            .freeze()
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

    internal func testFromProtoBody() throws {
        let protoData = Proto_TokenFeeScheduleUpdateTransactionBody.with { proto in
            proto.tokenID = Self.testTokenId.toProtobuf()
            proto.customFees = Self.testCustomFees.toProtobuf()
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.tokenFeeScheduleUpdate = protoData
            proto.transactionID = Resources.txId.toProtobuf()
        }

        let tx = try TokenFeeScheduleUpdateTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.tokenId, Self.testTokenId)
        XCTAssertEqual(tx.customFees, Self.testCustomFees)
    }

    internal func testGetSetTokenId() {
        let tx = TokenFeeScheduleUpdateTransaction()
        tx.tokenId(Self.testTokenId)

        XCTAssertEqual(tx.tokenId, Self.testTokenId)
    }

    internal func testGetSetCustomFees() {
        let tx = TokenFeeScheduleUpdateTransaction()
        tx.customFees(Self.testCustomFees)

        XCTAssertEqual(tx.customFees, Self.testCustomFees)
    }
}
