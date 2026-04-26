// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero
import XCTest

/// Base class for all Hiero tests with common utilities
open class HieroTestCase: XCTestCase {
    open override func setUp() async throws {
        try await super.setUp()
    }
}
