// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero

/// Centralized environment variable reading
/// All test configuration environment variables are read here in one place
public struct EnvironmentVariables {
    // MARK: - Raw Environment

    private static var env: [String: String] {
        ProcessInfo.processInfo.environment
    }

    // MARK: - Operator Configuration

    public static var operatorId: String? {
        env["HIERO_OPERATOR_ID"]?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static var operatorKey: String? {
        env["HIERO_OPERATOR_KEY"]?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Network Configuration

    public static var environmentType: String? {
        env["HIERO_ENVIRONMENT_TYPE"]
    }

    /// Comma-separated consensus node addresses (e.g., "127.0.0.1:50211,192.168.1.100:50211")
    public static var consensusNodes: [String] {
        guard let nodesStr = env["HIERO_CONSENSUS_NODES"] else { return [] }
        return nodesStr.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
    }

    /// Comma-separated consensus node account IDs (e.g., "0.0.3,0.0.4")
    /// Must match the count of consensusNodes
    public static var consensusNodeAccountIds: [String] {
        guard let idsStr = env["HIERO_CONSENSUS_NODE_ACCOUNT_IDS"] else { return [] }
        return idsStr.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
    }

    /// Comma-separated mirror node addresses (e.g., "mainnet.mirrornode.hedera.com:443")
    public static var mirrorNodes: [String] {
        guard let nodesStr = env["HIERO_MIRROR_NODES"] else { return [] }
        return nodesStr.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
    }

    // MARK: - Test Profile

    /// Returns the test profile, or default if not set
    public static var testProfile: String {
        env["HIERO_PROFILE"] ?? TestDefaults.profile.rawValue
    }

    // MARK: - Feature Flags

    /// Returns max test duration, or default if not set
    public static var maxTestDuration: TimeInterval {
        guard let durationStr = env["HIERO_MAX_DURATION"], let duration = TimeInterval(durationStr) else {
            return TestDefaults.maxTestDuration
        }
        return duration
    }

    /// Returns whether parallel execution is enabled, or default if not set
    public static var parallelExecution: Bool {
        guard let value = env["HIERO_PARALLEL"] else {
            return TestDefaults.parallelExecution
        }
        return value == "1"
    }

    /// Returns whether verbose logging is enabled, or default if not set
    public static var verboseLogging: Bool {
        guard let value = env["HIERO_VERBOSE"] else {
            return TestDefaults.verboseLogging
        }
        return value == "1"
    }

    // MARK: - Cleanup Policy

    /// Cleanup flag
    public static var enableCleanup: String? {
        env["HIERO_ENABLE_CLEANUP"]
    }

    /// Returns whether to cleanup accounts, or default if not set
    public static var cleanupAccounts: Bool {
        guard let value = env["HIERO_CLEANUP_ACCOUNTS"] else {
            return TestDefaults.cleanupAccounts
        }
        return value == "1"
    }

    /// Returns whether to cleanup tokens, or default if not set
    public static var cleanupTokens: Bool {
        guard let value = env["HIERO_CLEANUP_TOKENS"] else {
            return TestDefaults.cleanupTokens
        }
        return value == "1"
    }

    /// Returns whether to cleanup files, or default if not set
    public static var cleanupFiles: Bool {
        guard let value = env["HIERO_CLEANUP_FILES"] else {
            return TestDefaults.cleanupFiles
        }
        return value == "1"
    }

    /// Returns whether to cleanup topics, or default if not set
    public static var cleanupTopics: Bool {
        guard let value = env["HIERO_CLEANUP_TOPICS"] else {
            return TestDefaults.cleanupTopics
        }
        return value == "1"
    }

    /// Returns whether to cleanup contracts, or default if not set
    public static var cleanupContracts: Bool {
        guard let value = env["HIERO_CLEANUP_CONTRACTS"] else {
            return TestDefaults.cleanupContracts
        }
        return value == "1"
    }

    // MARK: - Helper: Check if Variable is Set

    public static func isSet(_ key: String) -> Bool {
        env[key] != nil
    }

    // MARK: - All Environment Variable Keys

    /// All known Hiero test environment variable keys
    /// This is the single source of truth for all supported environment variables
    public static let keys = [
        "HIERO_OPERATOR_ID",
        "HIERO_OPERATOR_KEY",
        "HIERO_PROFILE",
        "HIERO_ENVIRONMENT_TYPE",
        "HIERO_CONSENSUS_NODES",
        "HIERO_CONSENSUS_NODE_ACCOUNT_IDS",
        "HIERO_MIRROR_NODES",
        "HIERO_VERBOSE",
        "HIERO_MAX_DURATION",
        "HIERO_PARALLEL",
        "HIERO_ENABLE_CLEANUP",
        "HIERO_CLEANUP_ACCOUNTS",
        "HIERO_CLEANUP_TOKENS",
        "HIERO_CLEANUP_FILES",
        "HIERO_CLEANUP_TOPICS",
        "HIERO_CLEANUP_CONTRACTS",
    ]

    public static func printAllTestVariables() {
        let testVars = env.filter { $0.key.hasPrefix("HIERO_") }
        print("=== Test Environment Variables ===")
        for (key, value) in testVars.sorted(by: { $0.key < $1.key }) {
            print("\(key) = \(value)")
        }
        print("==================================")
    }
}
