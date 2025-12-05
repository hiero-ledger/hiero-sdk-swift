// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class ScheduleSignTransactionUnitTests: HieroUnitTestCase, TransactionTestable {
    typealias TransactionType = ScheduleSignTransaction

    static func makeTransaction() throws -> ScheduleSignTransaction {
        try ScheduleSignTransaction()
            .nodeAccountIds([AccountId("0.0.5005"), AccountId("0.0.5006")])
            .transactionId(
                TransactionId(
                    accountId: 5005, validStart: Timestamp(seconds: 1_554_158_542, subSecondNanos: 0), scheduled: false)
            )
            .scheduleId(ScheduleId.fromString("0.0.444"))
            .maxTransactionFee(1)
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
        let protoData = Proto_ScheduleSignTransactionBody.with { proto in
            proto.scheduleID = TestConstants.scheduleId.toProtobuf()
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.scheduleSign = protoData
            proto.transactionID = TestConstants.transactionId.toProtobuf()
        }

        let tx = try ScheduleSignTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.scheduleId, TestConstants.scheduleId)
    }

    internal func test_GetSetScheduleId() throws {
        let tx = ScheduleSignTransaction.init()
        tx.scheduleId(TestConstants.scheduleId)

        XCTAssertEqual(tx.scheduleId, TestConstants.scheduleId)
    }

    internal func test_ClearScheduleId() throws {
        let tx = ScheduleSignTransaction.init(scheduleId: TestConstants.scheduleId)
        tx.clearScheduleId()

        XCTAssertEqual(tx.scheduleId, nil)
    }
}
