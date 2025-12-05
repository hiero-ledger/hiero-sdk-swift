// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero

/// Validates environment variables and provides detailed error messages
public enum EnvironmentValidation {

    /// Validate that all required environment variables are set for a given profile
    public static func validate(for profile: TestProfile) throws {
        let envType = profile.environmentType

        // Validate operator credentials for environments that require them
        if envType.requiresOperator {
            try validateOperatorCredentials(for: profile)
        }

        // Validate network configuration
        try validateNetworkConfiguration(for: envType, profile: profile)
    }

    /// Validate operator credentials
    private static func validateOperatorCredentials(for profile: TestProfile) throws {
        guard EnvironmentVariables.operatorId != nil else {
            throw ValidationError.missingRequired(
                variable: "HIERO_OPERATOR_ID",
                reason: "Profile '\(profile.rawValue)' requires operator credentials",
                example: "0.0.1234"
            )
        }

        guard let operatorKey = EnvironmentVariables.operatorKey else {
            throw ValidationError.missingRequired(
                variable: "HIERO_OPERATOR_KEY",
                reason: "Profile '\(profile.rawValue)' requires operator credentials",
                example: "302e020100300506032b657004220420..."
            )
        }

        // Validate operator key format
        guard operatorKey.count >= 64 else {
            throw ValidationError.invalidValue(
                variable: "HIERO_OPERATOR_KEY",
                value: "\(operatorKey.prefix(20))...",
                reason: "Private key appears to be too short (minimum 64 characters for hex-encoded key)"
            )
        }
    }

    /// Validate network configuration
    private static func validateNetworkConfiguration(for type: TestEnvironmentType, profile: TestProfile) throws {
        let consensusNodes = EnvironmentVariables.consensusNodes
        let consensusAccountIds = EnvironmentVariables.consensusNodeAccountIds
        let mirrorNodes = EnvironmentVariables.mirrorNodes

        // For local environment, we need either consensus nodes OR rely on defaults
        if type == .local {
            // If consensus nodes are specified, validate them
            if !consensusNodes.isEmpty {
                guard !consensusAccountIds.isEmpty else {
                    throw ValidationError.missingRequired(
                        variable: "HIERO_CONSENSUS_NODE_ACCOUNT_IDS",
                        reason:
                            "When HIERO_CONSENSUS_NODES is specified, HIERO_CONSENSUS_NODE_ACCOUNT_IDS must also be provided",
                        example: "0.0.3,0.0.4,0.0.5"
                    )
                }
            }
            // Otherwise defaults will be used
        }

        // For development profile with mirror nodes but no consensus nodes,
        // Client.forMirrorNetwork will be used (which is valid)
        if profile == .development {
            if mirrorNodes.isEmpty && consensusNodes.isEmpty {
                throw ValidationError.missingRequired(
                    variable: "HIERO_MIRROR_NODES or HIERO_CONSENSUS_NODES",
                    reason:
                        "Development profile requires network configuration. Either specify mirror nodes for address book discovery, or consensus nodes for direct connection",
                    example: "HIERO_MIRROR_NODES=testnet.mirrornode.hedera.com:443"
                )
            }
        }

        // Validate consensus nodes and account IDs match
        if !consensusNodes.isEmpty && !consensusAccountIds.isEmpty {
            if consensusNodes.count != consensusAccountIds.count {
                // Warning, not error - we'll use as many as we can
                print(
                    "⚠️  WARNING: HIERO_CONSENSUS_NODES has \(consensusNodes.count) node(s), but HIERO_CONSENSUS_NODE_ACCOUNT_IDS has \(consensusAccountIds.count) ID(s). Will use the first \(min(consensusNodes.count, consensusAccountIds.count))."
                )
            }
        }
    }

    /// Validation errors
    public enum ValidationError: Error, CustomStringConvertible {
        case missingRequired(variable: String, reason: String, example: String)
        case invalidValue(variable: String, value: String, reason: String)
        case conflictingValues(variables: [String], reason: String)

        public var description: String {
            switch self {
            case .missingRequired(let variable, let reason, let example):
                return """
                    ❌ Missing required environment variable: \(variable)

                    Reason: \(reason)

                    Example: \(variable)=\(example)

                    Set this in your .env file or environment.
                    """

            case .invalidValue(let variable, let value, let reason):
                return """
                    ❌ Invalid value for environment variable: \(variable)

                    Current value: \(value)
                    Reason: \(reason)

                    Please check the value and try again.
                    """

            case .conflictingValues(let variables, let reason):
                return """
                    ❌ Conflicting environment variables: \(variables.joined(separator: ", "))

                    Reason: \(reason)

                    Please set only one of these variables, or ensure they are compatible.
                    """
            }
        }
    }
}

/// Extension to document all environment variables and their defaults
extension EnvironmentVariables {

    /// Documentation for all supported environment variables
    public static let documentation: [EnvironmentVariableDoc] = [
        // Operator Configuration
        EnvironmentVariableDoc(
            name: "HIERO_OPERATOR_ID",
            type: .string,
            required: .conditional("For integration tests"),
            defaultValue: nil,
            description: "Account ID of the operator account used for test transactions",
            example: "0.0.1234"
        ),
        EnvironmentVariableDoc(
            name: "HIERO_OPERATOR_KEY",
            type: .string,
            required: .conditional("For integration tests"),
            defaultValue: nil,
            description: "Private key for the operator account (hex-encoded)",
            example: "302e020100300506032b657004220420..."
        ),

        // Network Configuration
        EnvironmentVariableDoc(
            name: "HIERO_PROFILE",
            type: .enum(["local", "ciUnit", "ciIntegration", "development"]),
            required: .no,
            defaultValue: "local",
            description: "Test profile to use (determines environment type and feature flags)",
            example: "local"
        ),
        EnvironmentVariableDoc(
            name: "HIERO_ENVIRONMENT_TYPE",
            type: .enum(["unit", "local", "testnet", "previewnet", "mainnet", "custom"]),
            required: .no,
            defaultValue: "Determined by HIERO_PROFILE",
            description: "Explicitly override the environment type (usually set by profile)",
            example: "testnet"
        ),
        EnvironmentVariableDoc(
            name: "HIERO_CONSENSUS_NODES",
            type: .stringArray,
            required: .conditional("For local network or custom network setup"),
            defaultValue: "127.0.0.1:50211 (for local profile)",
            description: "Comma-separated list of consensus node addresses",
            example: "127.0.0.1:50211,192.168.1.100:50211"
        ),
        EnvironmentVariableDoc(
            name: "HIERO_CONSENSUS_NODE_ACCOUNT_IDS",
            type: .stringArray,
            required: .conditional("When HIERO_CONSENSUS_NODES is set"),
            defaultValue: "0.0.3 (for local profile)",
            description:
                "Comma-separated list of account IDs for consensus nodes (must match count of HIERO_CONSENSUS_NODES)",
            example: "0.0.3,0.0.4,0.0.5"
        ),
        EnvironmentVariableDoc(
            name: "HIERO_MIRROR_NODES",
            type: .stringArray,
            required: .conditional("For development profile or mirror network address book discovery"),
            defaultValue: "127.0.0.1:5600 (for local profile), empty otherwise",
            description:
                "Comma-separated list of mirror node addresses. If set without consensus nodes, uses Client.forMirrorNetwork",
            example: "testnet.mirrornode.hedera.com:443"
        ),

        // Feature Flags
        EnvironmentVariableDoc(
            name: "HIERO_MAX_DURATION",
            type: .number,
            required: .no,
            defaultValue: "300 (5 minutes)",
            description: "Maximum duration for a single test in seconds",
            example: "600"
        ),
        EnvironmentVariableDoc(
            name: "HIERO_PARALLEL",
            type: .boolean,
            required: .no,
            defaultValue: "Determined by profile (local: true, CI: false)",
            description: "Whether to run tests in parallel",
            example: "1"
        ),
        EnvironmentVariableDoc(
            name: "HIERO_VERBOSE",
            type: .boolean,
            required: .no,
            defaultValue: "false",
            description: "Enable verbose logging for debugging",
            example: "1"
        ),

        // Cleanup Policy
        EnvironmentVariableDoc(
            name: "HIERO_ENABLE_CLEANUP",
            type: .boolean,
            required: .no,
            defaultValue: nil,
            description:
                "Legacy: Enable/disable all cleanup (1=all, 0=none). Superseded by individual HIERO_CLEANUP_* flags",
            example: "1"
        ),
        EnvironmentVariableDoc(
            name: "HIERO_CLEANUP_ACCOUNTS",
            type: .boolean,
            required: .no,
            defaultValue: "true",
            description: "Cleanup test accounts after tests (recovers HBAR)",
            example: "1"
        ),
        EnvironmentVariableDoc(
            name: "HIERO_CLEANUP_TOKENS",
            type: .boolean,
            required: .no,
            defaultValue: "false",
            description: "Cleanup test tokens after tests (costs HBAR)",
            example: "1"
        ),
        EnvironmentVariableDoc(
            name: "HIERO_CLEANUP_FILES",
            type: .boolean,
            required: .no,
            defaultValue: "false",
            description: "Cleanup test files after tests (costs HBAR)",
            example: "1"
        ),
        EnvironmentVariableDoc(
            name: "HIERO_CLEANUP_TOPICS",
            type: .boolean,
            required: .no,
            defaultValue: "false",
            description: "Cleanup test topics after tests (costs HBAR)",
            example: "1"
        ),
        EnvironmentVariableDoc(
            name: "HIERO_CLEANUP_CONTRACTS",
            type: .boolean,
            required: .no,
            defaultValue: "true",
            description: "Cleanup test contracts after tests (can recover HBAR)",
            example: "1"
        ),
    ]

    /// Print documentation for all environment variables
    public static func printDocumentation() {
        print("=" * 80)
        print("TEST ENVIRONMENT VARIABLES DOCUMENTATION")
        print("=" * 80)
        print()

        var currentSection = ""
        for doc in documentation {
            let section = doc.name.components(separatedBy: "_")[1]
            if section != currentSection {
                currentSection = section
                print("\n## \(currentSection.uppercased())")
                print("-" * 80)
            }
            print(doc.formatted)
        }

        print("\n" + "=" * 80)
    }
}

/// Documentation for a single environment variable
public struct EnvironmentVariableDoc {
    public let name: String
    public let type: VariableType
    public let required: RequirementLevel
    public let defaultValue: String?
    public let description: String
    public let example: String

    public enum VariableType {
        case string
        case boolean
        case number
        case stringArray
        case `enum`([String])

        var description: String {
            switch self {
            case .string: return "String"
            case .boolean: return "Boolean (0 or 1)"
            case .number: return "Number"
            case .stringArray: return "String[] (comma-separated)"
            case .enum(let values): return "Enum: \(values.joined(separator: " | "))"
            }
        }
    }

    public enum RequirementLevel {
        case yes
        case no
        case conditional(String)

        var description: String {
            switch self {
            case .yes: return "✓ Required"
            case .no: return "✗ Optional"
            case .conditional(let condition): return "⚠ Conditional: \(condition)"
            }
        }
    }

    var formatted: String {
        """

        \(name)
          Type: \(type.description)
          Required: \(required.description)
          Default: \(defaultValue ?? "None")
          Description: \(description)
          Example: \(name)=\(example)
        """
    }
}

// Helper for string repetition
extension String {
    fileprivate static func * (lhs: String, rhs: Int) -> String {
        String(repeating: lhs, count: rhs)
    }
}
