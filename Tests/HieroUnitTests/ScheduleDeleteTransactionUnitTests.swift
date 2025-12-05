// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class ScheduleDeleteTransactionUnitTests: HieroUnitTestCase, TransactionTestable {
    typealias TransactionType = ScheduleDeleteTransaction

    static func makeTransaction() throws -> ScheduleDeleteTransaction {
        try ScheduleDeleteTransaction()
            .nodeAccountIds([AccountId("0.0.5005"), AccountId("0.0.5006")])
            .transactionId(
                TransactionId(
                    accountId: 5006, validStart: Timestamp(seconds: 1_554_158_542, subSecondNanos: 0), scheduled: false)
            )
            .scheduleId(ScheduleId("0.0.6006"))
            .maxTransactionFee(.fromTinybars(100_000))
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
        let protoData = Proto_ScheduleDeleteTransactionBody.with { proto in
            proto.scheduleID = TestConstants.scheduleId.toProtobuf()
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.transactionID = TestConstants.transactionId.toProtobuf()
            proto.scheduleDelete = protoData
        }

        let tx = try ScheduleDeleteTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.scheduleId, TestConstants.scheduleId)
    }

    internal func test_GetSetScheduleId() throws {
        let tx = ScheduleDeleteTransaction()
        tx.scheduleId(TestConstants.scheduleId)

        XCTAssertEqual(tx.scheduleId, TestConstants.scheduleId)
    }
}
