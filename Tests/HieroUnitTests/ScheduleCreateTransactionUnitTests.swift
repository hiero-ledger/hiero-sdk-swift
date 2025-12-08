// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class ScheduleCreateTransactionUnitTests: HieroUnitTestCase, TransactionTestable {
    typealias TransactionType = ScheduleCreateTransaction

    internal static let testMemo = "test memo"

    static func makeTransaction() throws -> ScheduleCreateTransaction {
        let transferTx = try TransferTransaction()
            .hbarTransfer(AccountId.fromString("0.0.555"), -10)
            .hbarTransfer(AccountId.fromString("0.0.321"), 10)

        return try transferTx.schedule()
            .nodeAccountIds([AccountId("0.0.5005"), AccountId("0.0.5006")])
            .transactionId(
                TransactionId(
                    accountId: 5006, validStart: Timestamp(seconds: 1_554_158_542, subSecondNanos: 0), scheduled: false)
            )
            .adminKey(.single(TestConstants.publicKey))
            .payerAccountId(AccountId.fromString("0.0.222"))
            .scheduleMemo("flook")
            .maxTransactionFee(1)
            .expirationTime(Timestamp(seconds: 1_554_158_567, subSecondNanos: 0))
            .freeze()
            .sign(TestConstants.privateKey)
    }

    internal func test_Serialize() throws {
        try assertTransactionSerializes()
    }

    internal func test_ToFromBytes() throws {
        try assertTransactionRoundTrips()
    }

    internal func test_FromProtoBody() throws {
        let protoData = Proto_ScheduleCreateTransactionBody.with { proto in
            proto.adminKey = Key.single(TestConstants.publicKey).toProtobuf()
            proto.expirationTime = TestConstants.validStart.toProtobuf()
            proto.payerAccountID = TestConstants.accountId.toProtobuf()
            proto.memo = "Flook"
            proto.waitForExpiry = true
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.scheduleCreate = protoData
            proto.transactionID = TestConstants.transactionId.toProtobuf()
        }

        let tx = try ScheduleCreateTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.adminKey, Key.single(TestConstants.publicKey))
        XCTAssertEqual(tx.expirationTime, TestConstants.validStart)
        XCTAssertEqual(tx.payerAccountId?.num, TestConstants.accountId.num)
        XCTAssertEqual(tx.scheduleMemo, "Flook")
        XCTAssertEqual(tx.isWaitForExpiry, true)
    }

    internal func test_GetSetPayerAccountId() throws {
        let tx = ScheduleCreateTransaction()
        tx.payerAccountId(TestConstants.accountId)

        XCTAssertEqual(tx.payerAccountId, TestConstants.accountId)
    }

    internal func test_GetSetAdminKey() throws {
        let tx = ScheduleCreateTransaction()
        tx.adminKey(.single(TestConstants.publicKey))

        XCTAssertEqual(tx.adminKey, .single(TestConstants.publicKey))
    }

    internal func test_GetSetExpirationTime() throws {
        let tx = ScheduleCreateTransaction()
        tx.expirationTime(TestConstants.validStart)

        XCTAssertEqual(tx.expirationTime, TestConstants.validStart)
    }

    internal func test_GetSetScheduleMemo() throws {
        let tx = ScheduleCreateTransaction()
        tx.scheduleMemo(Self.testMemo)

        XCTAssertEqual(tx.scheduleMemo, Self.testMemo)
    }

}
