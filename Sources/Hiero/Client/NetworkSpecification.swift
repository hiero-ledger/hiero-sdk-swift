// SPDX-License-Identifier: Apache-2.0

// MARK: - Network Specification

/// Generic specification for how to initialize a network.
///
/// Networks can be specified either by a predefined name (mainnet, testnet, etc.)
/// or by providing custom configuration data.
///
/// This generic enum eliminates duplication between consensus and mirror network specifications
/// while maintaining type safety for their different custom configuration types.
///
/// ## Usage
/// ```swift
/// // Predefined network
/// let spec: ConsensusNetworkSpecification = .predefined("testnet")
///
/// // Custom network with specific nodes
/// let spec: ConsensusNetworkSpecification = .custom(ConsensusNodeMap(...))
/// ```
internal enum NetworkSpecification<Custom: Decodable>: Decodable, Sendable where Custom: Sendable {
    /// Use a predefined network by name (e.g., "mainnet", "testnet", "previewnet", "localhost")
    case predefined(String)

    /// Use custom configuration data
    case custom(Custom)

    // MARK: - Decoding

    /// Decodes a network specification from JSON.
    ///
    /// Tries to decode as a string (network name) first, then as custom configuration.
    ///
    /// - Parameter decoder: The decoder to read data from
    /// - Throws: DecodingError if neither format can be decoded
    internal init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Try decoding as string (network name) first
        if let name = try? container.decode(String.self) {
            self = .predefined(name)
            return
        }

        // Try decoding as custom configuration
        if let custom = try? container.decode(Custom.self) {
            self = .custom(custom)
            return
        }

        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Expected either a network name (String) or custom configuration"
        )
    }
}

// MARK: - Consensus Node Map

/// Custom configuration for consensus networks mapping addresses to account IDs.
///
/// This wrapper type handles the conversion from string-based account IDs in JSON
/// to proper AccountId objects during decoding.
internal struct ConsensusNodeMap: Decodable, Sendable {
    /// Map of node addresses to their account IDs
    internal let addresses: [String: AccountId]

    // MARK: - Decoding

    /// Decodes a consensus node map from JSON.
    ///
    /// Converts string-based account IDs to AccountId objects.
    ///
    /// - Parameter decoder: The decoder to read data from
    /// - Throws: DecodingError if addresses cannot be parsed or account IDs are invalid
    internal init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let stringMap = try container.decode([String: String].self)

        do {
            self.addresses = try stringMap.mapValues { str throws -> AccountId in
                try AccountId.init(parsing: str)
            }
        } catch let error as HError {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Failed to parse account ID: \(error.description)",
                    underlyingError: error
                )
            )
        }
    }
}

// MARK: - Type Aliases

/// Specification for consensus network configuration.
///
/// Can be either:
/// - `.predefined(String)` - A network name like "mainnet"
/// - `.custom(ConsensusNodeMap)` - Custom node addresses with account IDs
internal typealias ConsensusNetworkSpecification = NetworkSpecification<ConsensusNodeMap>

/// Specification for mirror network configuration.
///
/// Can be either:
/// - `.predefined(String)` - A network name like "mainnet"
/// - `.custom([String])` - Custom mirror node addresses
internal typealias MirrorNetworkSpecification = NetworkSpecification<[String]>
