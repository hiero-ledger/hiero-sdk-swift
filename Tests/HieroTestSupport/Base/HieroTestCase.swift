// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero
import XCTest

/// Base class for all Hiero tests with common utilities
open class HieroTestCase: XCTestCase {
    open override func setUp() async throws {
        try await super.setUp()

        // Ensure .env and config are loaded (will throw XCTSkip if config fails)
        DotenvLoader.ensureLoaded()
        do {
            try TestEnvironmentConfig.ensureLoaded()
        } catch {
            throw XCTSkip("Failed to load test environment configuration: \(error)")
        }
    }
}
