// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Feature flags for controlling test behavior
public struct FeatureFlags {
    /// Maximum duration for a single test (in seconds)
    public var maxTestDuration: TimeInterval

    /// Whether to run tests in parallel
    public var parallelExecution: Bool

    /// Verbose logging for debugging
    public var verboseLogging: Bool

    /// Policy for cleaning up test resources
    public var cleanupPolicy: CleanupPolicy

    public init(
        maxTestDuration: TimeInterval,
        parallelExecution: Bool,
        verboseLogging: Bool,
        cleanupPolicy: CleanupPolicy
    ) {
        self.maxTestDuration = maxTestDuration
        self.parallelExecution = parallelExecution
        self.verboseLogging = verboseLogging
        self.cleanupPolicy = cleanupPolicy
    }

    /// Returns default feature flags (without reading environment)
    /// Use this for builders or when you want baseline defaults
    /// Values come from TestDefaults.swift
    public static var defaults: Self {
        FeatureFlags(
            maxTestDuration: TestDefaults.maxTestDuration,
            parallelExecution: TestDefaults.parallelExecution,
            verboseLogging: TestDefaults.verboseLogging,
            cleanupPolicy: .economical
        )
    }

    /// Load feature flags from environment variables
    /// Defaults are applied at the EnvironmentVariables layer
    public static func fromEnvironment() -> Self {
        FeatureFlags(
            maxTestDuration: EnvironmentVariables.maxTestDuration,
            parallelExecution: EnvironmentVariables.parallelExecution,
            verboseLogging: EnvironmentVariables.verboseLogging,
            cleanupPolicy: CleanupPolicy.fromEnvironment()
        )
    }

    // MARK: - Profile-Specific Feature Flags

    /// Local development - supports both unit and integration tests
    /// Use test filters to control which tests run
    public static var local: Self {
        FeatureFlags(
            maxTestDuration: 300,
            parallelExecution: false,
            verboseLogging: false,
            cleanupPolicy: .economical
        )
    }

    /// CI unit tests only
    public static var ciUnit: Self {
        FeatureFlags(
            maxTestDuration: 120,
            parallelExecution: true,
            verboseLogging: true,
            cleanupPolicy: .none
        )
    }

    /// CI integration tests
    public static var ciIntegration: Self {
        FeatureFlags(
            maxTestDuration: 600,
            parallelExecution: true,
            verboseLogging: true,
            cleanupPolicy: .none
        )
    }

    /// Development environment - integration tests
    public static var development: Self {
        FeatureFlags(
            maxTestDuration: 300,
            parallelExecution: false,
            verboseLogging: true,
            cleanupPolicy: .economical
        )
    }

    // MARK: - Environment Variable Overrides

    /// Apply environment variable overrides to this feature flags instance
    /// This allows using a profile but overriding specific flags via env vars
    public func withEnvironmentOverrides() -> Self {
        var flags = self

        // Only apply overrides if the environment variable is explicitly set
        if EnvironmentVariables.isSet("HIERO_MAX_DURATION") {
            flags.maxTestDuration = EnvironmentVariables.maxTestDuration
        }

        if EnvironmentVariables.isSet("HIERO_PARALLEL") {
            flags.parallelExecution = EnvironmentVariables.parallelExecution
        }

        if EnvironmentVariables.isSet("HIERO_VERBOSE") {
            flags.verboseLogging = EnvironmentVariables.verboseLogging
        }

        // Check for cleanup policy overrides
        if EnvironmentVariables.isSet("HIERO_ENABLE_CLEANUP") || EnvironmentVariables.isSet("HIERO_CLEANUP_ACCOUNTS") {
            flags.cleanupPolicy = CleanupPolicy.fromEnvironment()
        }

        return flags
    }
}
