// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Centralized default values for all test configuration
/// This is the single source of truth for defaults used across:
/// - EnvironmentVariables
/// - FeatureFlags
/// - CleanupPolicy
/// - TestProfile
public struct TestDefaults {
    // MARK: - Test Profile

    public static let profile: TestProfile = .local
    public static let environmentType: TestEnvironmentType = .local

    // MARK: - Feature Flags

    public static let maxTestDuration: TimeInterval = 300
    public static let parallelExecution: Bool = false
    public static let verboseLogging: Bool = false

    // MARK: - Cleanup Policy

    public static let cleanupAccounts: Bool = true
    public static let cleanupTokens: Bool = false
    public static let cleanupFiles: Bool = false
    public static let cleanupTopics: Bool = false
    public static let cleanupContracts: Bool = true

    // MARK: - Local Network Configuration

    public static let localConsensusNode: String = "127.0.0.1:50211"
    public static let localConsensusNodeAccountId: String = "0.0.3"
    public static let localMirrorNode: String = "127.0.0.1:5600"
}
