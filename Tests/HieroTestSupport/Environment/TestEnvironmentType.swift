// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Defines the type of test environment
public enum TestEnvironmentType: String, Codable {
    /// Unit tests - no network required
    case unit

    /// Local node environment
    case local

    /// Hedera testnet
    case testnet

    /// Hedera previewnet
    case previewnet

    /// Hedera mainnet (use with caution in tests)
    case mainnet

    /// Custom network environment
    case custom

    /// Whether this environment type requires an operator account
    public var requiresOperator: Bool {
        switch self {
        case .unit:
            return false
        default:
            return true
        }
    }

    /// Whether this environment type requires network connectivity
    public var requiresNetwork: Bool {
        switch self {
        case .unit:
            return false
        default:
            return true
        }
    }

    /// Default network name for this environment type
    public var defaultNetworkName: String {
        switch self {
        case .local, .unit, .custom:
            return "localhost"
        case .testnet:
            return "testnet"
        case .previewnet:
            return "previewnet"
        case .mainnet:
            return "mainnet"
        }
    }
}
