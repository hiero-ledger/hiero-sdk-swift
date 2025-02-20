/*
 * ‌
 * Hedera Swift SDK
 *
 * Copyright (C) 2023 - 2023 Hedera Hashgraph, LLC
 *
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

internal final class TransactionReceiptTests: XCTestCase {
    private func createReceipt() throws -> TransactionReceipt {
        try TransactionReceipt.init(
            transactionId: nil,
            status: Status.scheduleAlreadyDeleted,
            accountId: AccountId.fromString("1.2.3"),
            fileId: FileId.fromString("4.5.6"),
            contractId: ContractId.fromString("3.2.1"),
            topicId: TopicId.fromString("9.8.7"),
            topicSequenceNumber: 3,
            topicRunningHash: "running hash".data(using: .utf8),
            topicRunningHashVersion: 0,
            tokenId: TokenId.fromString("6.5.4"),
            totalSupply: 30,
            scheduleId: ScheduleId.fromString("1.1.1"),
            scheduledTransactionId: TransactionId.init(
                accountId: AccountId(5006),
                validStart: Timestamp(seconds: 1_554_158_542, subSecondNanos: 0), scheduled: false),
            serials: [1, 2, 3],
            duplicates: [],
            children: [])
    }

    internal func testSerialize() throws {
        let receipt = try createReceipt()

        let receiptBytes = receipt.toBytes()

        let copyReceipt = try TransactionReceipt.fromBytes(receiptBytes)

        XCTAssertEqual(receipt.toProtobuf(), copyReceipt.toProtobuf())

        assertSnapshot(matching: receipt, as: .description)
    }
}
