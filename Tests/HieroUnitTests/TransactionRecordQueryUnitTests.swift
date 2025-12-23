// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class TransactionRecordQueryUnitTests: HieroUnitTestCase, QueryTestable {
    static func makeQueryProto() -> Proto_Query {
        let validStart = Timestamp(fromUnixTimestampNanos: 1_641_088_801 * 1_000_000_000 + 2)

        let transactionId: TransactionId = TransactionId(
            accountId: "0.0.31415",
            validStart: validStart,
            scheduled: false,
            nonce: nil
        )
        return TransactionRecordQuery()
            .transactionId(transactionId)
            .includeChildren(true)
            .includeDuplicates(true)
            .toQueryProtobufWith(.init())
    }

    internal func test_Serialize() throws {
        try assertQuerySerializes()
    }
}
