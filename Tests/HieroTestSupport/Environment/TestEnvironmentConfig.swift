// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero

/// Complete test environment configuration
public struct TestEnvironmentConfig {
    public let type: TestEnvironmentType
    public let network: NetworkConfig
    public let `operator`: OperatorConfig?
    public let features: FeatureFlags
    public let profile: TestProfile

    /// Singleton instance loaded exactly once from environment
    private static let _shared: Result<TestEnvironmentConfig, Error> = {
        Result { try fromEnvironment() }
    }()

    /// Shared configuration instance (loaded once from environment)
    ///
    /// This is the only way to access configuration in tests.
    /// The configuration is loaded once and cached for the duration of the test run.
    public static var shared: TestEnvironmentConfig {
        get throws {
            try _shared.get()
        }
    }

    /// Ensures the configuration has been loaded (call early to fail fast)
    public static func ensureLoaded() throws {
        _ = try shared
    }

    private init(
        type: TestEnvironmentType,
        network: NetworkConfig,
        operator: OperatorConfig?,
        features: FeatureFlags,
        profile: TestProfile
    ) {
        self.type = type
        self.network = network
        self.operator = `operator`
        self.features = features
        self.profile = profile
    }

    /// Load configuration from environment (creates new instance each time)
    private static func fromEnvironment() throws -> Self {
        let profile = TestProfile.fromEnvironment()

        // Validate environment variables for this profile
        try EnvironmentValidation.validate(for: profile)

        let envType = profile.environmentType

        // Override with explicit environment variable if set
        let type: TestEnvironmentType
        if let envTypeStr = EnvironmentVariables.environmentType,
            let explicitType = TestEnvironmentType(rawValue: envTypeStr)
        {
            type = explicitType
        } else {
            type = envType
        }

        let network = NetworkConfig.fromEnvironmentType(type)
        let operatorConfig = try OperatorConfig.fromEnvironment()

        // Check if we need an operator but don't have one
        if type.requiresOperator && operatorConfig == nil {
            throw TestEnvironmentError.missingOperatorCredentials
        }

        // Start with profile's feature flags, then apply environment variable overrides
        let features = profile.featureFlags.withEnvironmentOverrides()

        return TestEnvironmentConfig(
            type: type,
            network: network,
            operator: operatorConfig,
            features: features,
            profile: profile
        )
    }
}

/// Errors that can occur when setting up test environment
public enum TestEnvironmentError: Error, CustomStringConvertible {
    case missingOperatorCredentials
    case invalidConfiguration(String)
    case networkUnavailable

    public var description: String {
        switch self {
        case .missingOperatorCredentials:
            return
                "Operator credentials are required but not provided. Set TEST_OPERATOR_ID and TEST_OPERATOR_KEY environment variables."
        case .invalidConfiguration(let message):
            return "Invalid test environment configuration: \(message)"
        case .networkUnavailable:
            return "Test network is unavailable"
        }
    }
}
