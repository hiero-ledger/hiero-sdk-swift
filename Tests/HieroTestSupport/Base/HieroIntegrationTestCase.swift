// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero
import XCTest

/// Base class for integration tests (requires network)
open class HieroIntegrationTestCase: HieroTestCase {
    /// Test environment with operator
    public var testEnv: IntegrationTestEnvironment!

    /// Resource manager for automatic cleanup
    internal var resourceManager: ResourceManager!

    open override func setUp() async throws {
        try await super.setUp()

        // Integration tests require .env configuration and operator credentials.
        DotenvLoader.ensureLoaded()
        do {
            try TestEnvironmentConfig.ensureLoaded()
        } catch {
            throw XCTSkip("Failed to load test environment configuration: \(error)")
        }

        // Create test environment (validates config and operator)
        testEnv = try await IntegrationTestEnvironment.create()

        // Create resource manager
        let config = try TestEnvironmentConfig.shared
        resourceManager = ResourceManager(
            client: testEnv.client,
            operatorAccountId: testEnv.operator.accountId,
            operatorPrivateKey: testEnv.operator.privateKey,
            cleanupPolicy: config.features.cleanupPolicy
        )
    }

    open override func tearDown() async throws {
        // Clean up resources according to policy
        if let manager = resourceManager {
            try await manager.cleanup()
        }

        try await super.tearDown()
    }
}
