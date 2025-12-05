// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import Logging
import XCTest

internal class NodeAddressBookQueryIntegrationTests: HieroIntegrationTestCase {
    internal func test_AddressBook() async throws {
        // Given / When / Then
        _ = try await NodeAddressBookQuery().execute(testEnv.client)
    }
}
