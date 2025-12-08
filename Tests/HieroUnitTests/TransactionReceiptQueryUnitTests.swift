// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class TransactionReceiptQueryUnitTests: HieroUnitTestCase {
    internal func test_Serialize() throws {
        let validStart = Timestamp(fromUnixTimestampNanos: 1_641_088_801 * 1_000_000_000 + 2)

        let transactionId: TransactionId = TransactionId(
            accountId: "0.0.31415",
            validStart: validStart,
            scheduled: false,
            nonce: nil
        )
        let query = TransactionReceiptQuery()
            .transactionId(transactionId)
            .toQueryProtobufWith(.init())

        SnapshotTesting.assertSnapshot(of: query, as: .description)
    }
}
