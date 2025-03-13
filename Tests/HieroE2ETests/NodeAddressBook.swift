// SPDX-License-Identifier: Apache-2.0

import Hiero
import Logging
import XCTest

internal class NodeAddressBook: XCTestCase {
    internal func testAddressBook() async throws {
        let testEnv = TestEnvironment.global

        _ = try await NodeAddressBookQuery().execute(testEnv.client)
    }
}
