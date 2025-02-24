/*
 * ‌
 * Hedera Swift SDK
 * ​
 * Copyright (C) 2023 - 2023 Hedera Hashgraph, LLC
 * ​
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ‍
 */

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class ScheduleDeleteTransactionTests: XCTestCase {
    private static func makeTransaction() throws -> ScheduleDeleteTransaction {
        try ScheduleDeleteTransaction()
            .nodeAccountIds([AccountId("0.0.5005"), AccountId("0.0.5006")])
            .transactionId(
                TransactionId(
                    accountId: 5006, validStart: Timestamp(seconds: 1_554_158_542, subSecondNanos: 0), scheduled: false)
            )
            .scheduleId(ScheduleId("0.0.6006"))
            .maxTransactionFee(.fromTinybars(100_000))
            .freeze()
            .sign(Resources.privateKey)
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
        let protoData = Proto_ScheduleDeleteTransactionBody.with { proto in
            proto.scheduleID = Resources.scheduleId.toProtobuf()
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.transactionID = Resources.txId.toProtobuf()
            proto.scheduleDelete = protoData
        }

        let tx = try ScheduleDeleteTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.scheduleId, Resources.scheduleId)
    }

    internal func testGetSetScheduleId() throws {
        let tx = ScheduleDeleteTransaction()
        tx.scheduleId(Resources.scheduleId)

        XCTAssertEqual(tx.scheduleId, Resources.scheduleId)
    }
}
