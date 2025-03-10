// SPDX-License-Identifier: Apache-2.0

import Hiero
import XCTest

internal class Prng: XCTestCase {
    internal func testBasic() async throws {
        let testEnv = try TestEnvironment.nonFree

        let record =
            try await PrngTransaction().range(100).execute(testEnv.client).getRecord(testEnv.client)

        let prngNumber = try XCTUnwrap(record.prngNumber)
        XCTAssertLessThan(prngNumber, 100)
    }
}
