// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Predefined test profiles for different testing scenarios
public enum TestProfile: String, Codable {
    /// Local development (unit and integration tests)
    /// Use test filters to control which tests run: --filter HieroUnitTests or --filter HieroIntegrationTests
    case local

    /// CI unit tests
    case ciUnit

    /// CI integration tests
    case ciIntegration

    /// Integration tests in another environment (testnet, previewnet, custom)
    case development

    /// Get the test environment type for this profile
    public var environmentType: TestEnvironmentType {
        switch self {
        case .ciUnit:
            return .unit
        case .local, .ciIntegration:
            return .local
        case .development:
            return .testnet  // Default to testnet for development
        }
    }

    /// Get feature flags for this profile
    public var featureFlags: FeatureFlags {
        switch self {
        case .local:
            return .local
        case .ciUnit:
            return .ciUnit
        case .ciIntegration:
            return .ciIntegration
        case .development:
            return .development
        }
    }

    /// Load profile from environment variable
    public static func fromEnvironment() -> Self {
        let profileStr = EnvironmentVariables.testProfile

        // Try to parse the profile
        guard let profile = TestProfile(rawValue: profileStr) else {
            // Invalid profile - print warning and fall back to default
            print(
                "WARNING: Invalid HIERO_PROFILE value '\(profileStr)'. Valid values: local, ciUnit, ciIntegration, development"
            )
            print("Falling back to default profile: 'local'")
            return .local
        }
        // Valid profile
        if EnvironmentVariables.verboseLogging {
            if EnvironmentVariables.isSet("HIERO_PROFILE") {
                print("Using test profile: '\(profileStr)'")
            } else {
                print("No HIERO_PROFILE specified, using default: '\(profileStr)'")
            }
        }
        return profile
    }
}
