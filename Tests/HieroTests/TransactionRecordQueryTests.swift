// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class TransactionRecordQueryTests: XCTestCase {
    internal func testSerialize() throws {
        let validStart = Timestamp(fromUnixTimestampNanos: 1_641_088_801 * 1_000_000_000 + 2)

        let transactionId: TransactionId = TransactionId(
            accountId: "0.0.31415",
            validStart: validStart,
            scheduled: false,
            nonce: nil
        )
        let query = TransactionRecordQuery()
            .transactionId(transactionId)
            .includeChildren(true)
            .includeDuplicates(true)
            .toQueryProtobufWith(.init())

        assertSnapshot(of: query, as: .description)
    }
}
