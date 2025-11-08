// SPDX-License-Identifier: Apache-2.0

import NIOCore

// MARK: - Network Factory

/// Factory for creating consensus and mirror networks from specifications.
///
/// Centralizes all network creation logic and provides a consistent interface
/// for creating networks from different sources (predefined names, custom addresses, etc.).
///
/// ## Supported Networks
/// - **mainnet** - Hedera production network
/// - **testnet** - Hedera test network
/// - **previewnet** - Hedera preview network
/// - **localhost** - Local development network
///
/// ## Design Pattern
/// This is an enum with no cases to prevent instantiation - it serves purely as a namespace
/// for static factory methods.
///
/// ## Related Types
/// - `NetworkSpecification` - Defines network specification format
/// - `ConsensusNetworkConfig` - Pre-configured network addresses
/// - `Client` - Uses factory to create networks from JSON config
internal enum NetworkFactory {
    // MARK: - Consensus Network Creation
    
    /// Creates a consensus network from a specification.
    ///
    /// - Parameters:
    ///   - spec: Network specification (predefined name or custom addresses)
    ///   - eventLoop: Event loop group for managing connections
    ///   - shard: Shard number for custom networks (default: 0)
    ///   - realm: Realm number for custom networks (default: 0)
    /// - Returns: Configured consensus network
    /// - Throws: HError if network name is unknown or addresses are invalid
    static func makeConsensusNetwork(
        spec: ConsensusNetworkSpecification,
        eventLoop: EventLoopGroup,
        shard: UInt64 = 0,
        realm: UInt64 = 0
    ) throws -> ConsensusNetwork {
        switch spec {
        case .predefined(let name):
            return try makeConsensusNetworkByName(name, eventLoop: eventLoop, shard: shard, realm: realm)
            
        case .custom(let nodeMap):
            return try ConsensusNetwork(addresses: nodeMap.addresses, eventLoop: eventLoop.next())
        }
    }
    
    /// Creates a consensus network from a predefined network name.
    ///
    /// - Parameters:
    ///   - name: Network name ("mainnet", "testnet", "previewnet", or "localhost")
    ///   - eventLoop: Event loop group for managing connections
    ///   - shard: Shard number for localhost (default: 0)
    ///   - realm: Realm number for localhost (default: 0)
    /// - Returns: Configured consensus network
    /// - Throws: HError if network name is unknown
    static func makeConsensusNetworkByName(
        _ name: borrowing String,
        eventLoop: EventLoopGroup,
        shard: UInt64 = 0,
        realm: UInt64 = 0
    ) throws -> ConsensusNetwork {
        switch name.lowercased() {
        case "mainnet":
            return .mainnet(eventLoop)
            
        case "testnet":
            return .testnet(eventLoop)
            
        case "previewnet":
            return .previewnet(eventLoop)
            
        case "localhost":
            let addresses: [String: AccountId] = ["127.0.0.1:50211": AccountId(num: 3)]
            return try ConsensusNetwork(addresses: addresses, eventLoop: eventLoop.next())
            
        default:
            throw HError.basicParse("Unknown network name '\(name)'. Valid names: mainnet, testnet, previewnet, localhost")
        }
    }
    
    // MARK: - Mirror Network Creation
    
    /// Creates a mirror network from a specification.
    ///
    /// - Parameters:
    ///   - spec: Mirror network specification (predefined name or custom addresses)
    ///   - eventLoop: Event loop group for managing connections
    /// - Returns: Configured mirror network
    /// - Throws: HError if network name is unknown
    static func makeMirrorNetwork(
        spec: MirrorNetworkSpecification?,
        eventLoop: EventLoopGroup
    ) throws -> MirrorNetwork {
        guard let spec = spec else {
            // No mirror network specified - return empty mirror network
            return MirrorNetwork(targets: [], eventLoop: eventLoop)
        }
        
        switch spec {
        case .predefined(let name):
            return try makeMirrorNetworkByName(name, eventLoop: eventLoop)
            
        case .custom(let addresses):
            return MirrorNetwork(targets: addresses, eventLoop: eventLoop)
        }
    }
    
    /// Creates a mirror network from a predefined network name.
    ///
    /// - Parameters:
    ///   - name: Network name ("mainnet", "testnet", "previewnet", or "localhost")
    ///   - eventLoop: Event loop group for managing connections
    /// - Returns: Configured mirror network
    /// - Throws: HError if network name is unknown
    static func makeMirrorNetworkByName(
        _ name: borrowing String,
        eventLoop: EventLoopGroup
    ) throws -> MirrorNetwork {
        switch name.lowercased() {
        case "mainnet":
            return .mainnet(eventLoop)
            
        case "testnet":
            return .testnet(eventLoop)
            
        case "previewnet":
            return .previewnet(eventLoop)
            
        case "localhost":
            return .localhost(eventLoop)
            
        default:
            throw HError.basicParse("Unknown mirror network name '\(name)'. Valid names: mainnet, testnet, previewnet, localhost")
        }
    }
    
    // MARK: - Ledger ID Helper
    
    /// Determines the appropriate ledger ID for a network name.
    ///
    /// - Parameter name: Network name
    /// - Returns: Ledger ID for the network, or nil for custom/localhost networks
    static func ledgerIdForNetworkName(_ name: borrowing String) -> LedgerId? {
        switch name.lowercased() {
        case "mainnet":
            return .mainnet
        case "testnet":
            return .testnet
        case "previewnet":
            return .previewnet
        default:
            return nil
        }
    }
}

