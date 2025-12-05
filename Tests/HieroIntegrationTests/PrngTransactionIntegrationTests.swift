// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal class PrngTransactionIntegrationTests: HieroIntegrationTestCase {
    internal func test_Basic() async throws {
        // Given / When
        let record = try await PrngTransaction()
            .range(100)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        // Then
        let prngNumber = try XCTUnwrap(record.prngNumber)
        XCTAssertLessThan(prngNumber, 100)
    }
}
