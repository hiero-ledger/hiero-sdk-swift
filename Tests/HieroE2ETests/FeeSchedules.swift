// SPDX-License-Identifier: Apache-2.0

import Hiero
import XCTest

internal class FeeSchedulesQuery: XCTestCase {
    internal func testBasic() async throws {
        let testEnv = try TestEnvironment.nonFree

        let feeScheduleBytes =
            try await FileContentsQuery().fileId(FileId.fromString("0.0.111")).execute(testEnv.client)

        let feeSchedules = try FeeSchedules.fromBytes(feeScheduleBytes.contents)

        XCTAssertNotNil(feeSchedules.current)
    }
}
