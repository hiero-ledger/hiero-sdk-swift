// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Policy for cleaning up test resources
/// Different resource types have different economics:
/// - Accounts: Cleanup recovers HBAR (always beneficial)
/// - Contracts: Cleanup can recover HBAR (beneficial)
/// - Tokens/Files/Topics: Cleanup only costs HBAR (optional)
public struct CleanupPolicy {
    /// Cleanup accounts (recommended: recovers locked HBAR)
    public var cleanupAccounts: Bool = TestDefaults.cleanupAccounts

    /// Cleanup tokens (optional: costs HBAR, no recovery)
    public var cleanupTokens: Bool = TestDefaults.cleanupTokens

    /// Cleanup files (optional: costs HBAR, no recovery)
    public var cleanupFiles: Bool = TestDefaults.cleanupFiles

    /// Cleanup topics (optional: costs HBAR, no recovery)
    public var cleanupTopics: Bool = TestDefaults.cleanupTopics

    /// Cleanup contracts (recommended: can recover HBAR)
    public var cleanupContracts: Bool = TestDefaults.cleanupContracts

    /// Initialize with explicit values
    /// All parameters are required - use predefined policies (.none, .economical, .all) or fromEnvironment() for defaults
    public init(
        cleanupAccounts: Bool,
        cleanupTokens: Bool,
        cleanupFiles: Bool,
        cleanupTopics: Bool,
        cleanupContracts: Bool
    ) {
        self.cleanupAccounts = cleanupAccounts
        self.cleanupTokens = cleanupTokens
        self.cleanupFiles = cleanupFiles
        self.cleanupTopics = cleanupTopics
        self.cleanupContracts = cleanupContracts
    }

    // MARK: - Predefined Policies

    /// No cleanup - for ephemeral networks or when cleanup isn't needed
    public static var none: Self {
        CleanupPolicy(
            cleanupAccounts: false,
            cleanupTokens: false,
            cleanupFiles: false,
            cleanupTopics: false,
            cleanupContracts: false
        )
    }

    /// Economic cleanup - only cleanup resources that recover HBAR
    /// Default policy for most scenarios
    public static var economical: Self {
        CleanupPolicy(
            cleanupAccounts: true,
            cleanupTokens: false,
            cleanupFiles: false,
            cleanupTopics: false,
            cleanupContracts: true
        )
    }

    /// Full cleanup - cleanup everything (for local nodes or when tidiness matters)
    public static var all: Self {
        CleanupPolicy(
            cleanupAccounts: true,
            cleanupTokens: true,
            cleanupFiles: true,
            cleanupTopics: true,
            cleanupContracts: true
        )
    }

    /// Load from environment variables
    /// Defaults are applied at the EnvironmentVariables layer
    public static func fromEnvironment() -> Self {
        // Check for legacy TEST_ENABLE_CLEANUP first
        if let cleanup = EnvironmentVariables.enableCleanup {
            return cleanup == "1" ? .all : .none
        }

        // Use values from EnvironmentVariables (which include defaults)
        return CleanupPolicy(
            cleanupAccounts: EnvironmentVariables.cleanupAccounts,
            cleanupTokens: EnvironmentVariables.cleanupTokens,
            cleanupFiles: EnvironmentVariables.cleanupFiles,
            cleanupTopics: EnvironmentVariables.cleanupTopics,
            cleanupContracts: EnvironmentVariables.cleanupContracts
        )
    }
}
