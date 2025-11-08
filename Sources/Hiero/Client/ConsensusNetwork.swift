// SPDX-License-Identifier: Apache-2.0

import Atomics
import Foundation
import GRPC
import NIOConcurrencyHelpers
import NIOCore

// MARK: - Consensus Network

/// Manages connections to consensus nodes on the Hedera network.
///
/// The consensus network maintains a pool of node connections with health tracking
/// and automatic failover. It supports dynamic network updates and node selection
/// strategies for optimal performance and reliability.
internal final class ConsensusNetwork: Sendable, AtomicReference {
    // MARK: - Constants
    
    /// Port priority for selecting service endpoints (lower values = higher priority)
    private static let portPriority: [UInt16: Int] = [
        NodeConnection.consensusTlsPort: 0,
        NodeConnection.consensusPlaintextPort: 1
    ]
    
    // MARK: - Properties
    
    /// Maps account IDs to their index in the nodes array
    internal let nodeIndexMap: [AccountId: Int]
    
    /// Array of all consensus node account IDs
    internal let nodes: [AccountId]
    
    /// Health status tracking for each node
    private let nodeHealthStates: [NIOLockedValueBox<NodeHealth>]
    
    /// GRPC connections to each node
    private let nodeConnections: [NodeConnection]
    
    // MARK: - Initialization
    
    /// Internal initializer for creating a consensus network.
    private init(
        map: [AccountId: Int],
        nodes: [AccountId],
        health: [NIOLockedValueBox<NodeHealth>],
        connections: [NodeConnection]
    ) {
        self.nodeIndexMap = map
        self.nodes = nodes
        self.nodeHealthStates = health
        self.nodeConnections = connections
    }

    /// Creates a consensus network from configuration.
    fileprivate convenience init(config: ConsensusNetworkConfig, eventLoop: NIOCore.EventLoopGroup) {
        let connections = config.addresses.map { addresses in
            let addresses = Set(addresses.map { HostAndPort(host: $0, port: 50211) })
            return NodeConnection(eventLoop: eventLoop.next(), addresses: addresses)
        }

        let health: [NIOLockedValueBox<NodeHealth>] = (0..<config.nodes.count).map { _ in .init(.unused) }

        self.init(
            map: config.nodeIndexMap,
            nodes: config.nodes,
            health: health,
            connections: connections
        )
    }

    /// Creates a consensus network from address mappings.
    ///
    /// - Parameters:
    ///   - addresses: Dictionary mapping address strings to account IDs
    ///   - eventLoop: Event loop for managing connections
    internal convenience init(addresses: [String: AccountId], eventLoop: EventLoop) throws {
        let tmp = try Self.withAddresses(
            Self(map: [:], nodes: [], health: [], connections: []), addresses: addresses, eventLoop: eventLoop)
        self.init(map: tmp.nodeIndexMap, nodes: tmp.nodes, health: tmp.nodeHealthStates, connections: tmp.nodeConnections)
    }
    
    // MARK: - Computed Properties
    
    /// Returns a dictionary of all network addresses mapped to their account IDs.
    internal var addresses: [String: AccountId] {
        Dictionary(
            nodeIndexMap.lazy.flatMap { (account, index) in
                self.nodeConnections[index].addresses.lazy.map { (String(describing: $0), account) }
            },
            uniquingKeysWith: { first, _ in first }
        )
    }
    
    // MARK: - Factory Methods
    
    /// Creates a consensus network pre-configured for Hedera mainnet.
    internal static func mainnet(_ eventLoop: NIOCore.EventLoopGroup) -> Self {
        Self(config: ConsensusNetworkConfig.mainnet, eventLoop: eventLoop)
    }

    /// Creates a consensus network pre-configured for Hedera testnet.
    internal static func testnet(_ eventLoop: NIOCore.EventLoopGroup) -> Self {
        Self(config: ConsensusNetworkConfig.testnet, eventLoop: eventLoop)
    }

    /// Creates a consensus network pre-configured for Hedera previewnet.
    internal static func previewnet(_ eventLoop: NIOCore.EventLoopGroup) -> Self {
        Self(config: ConsensusNetworkConfig.previewnet, eventLoop: eventLoop)
    }
    
    // MARK: - Network Updates
    
    /// Converts a node address book to a network address dictionary.
    ///
    /// - Parameter addressBook: Array of node addresses from the address book
    /// - Returns: Dictionary mapping address strings to account IDs
    internal static func addressMap(from addressBook: [NodeAddress]) -> [String: AccountId] {
        var network = [String: AccountId]()

        for nodeAddress in addressBook {
            for endpoint in nodeAddress.serviceEndpoints {
                network[endpoint.description] = nodeAddress.nodeAccountId
            }
        }

        return network
    }

    /// Creates an updated network from an address book, reusing existing connections where possible.
    ///
    /// This method intelligently updates the network by:
    /// - Reusing connections and health status for unchanged nodes
    /// - Replacing connections for nodes with different addresses
    /// - Adding new nodes as needed
    /// - Removing nodes no longer in the address book
    ///
    /// - Parameters:
    ///   - old: The existing consensus network
    ///   - eventLoop: Event loop for new connections
    ///   - addressBook: The new node address book
    /// - Returns: An updated consensus network
    internal static func withAddressBook(_ old: ConsensusNetwork, eventLoop: EventLoop, _ addressBook: NodeAddressBook) -> Self
    {
        let addressBook = addressBook.nodeAddresses

        // Pre-allocate arrays to avoid reallocation during iteration
        var map: [AccountId: Int] = [:]
        map.reserveCapacity(addressBook.count)
        
        var nodeIds: [AccountId] = []
        nodeIds.reserveCapacity(addressBook.count)
        
        var health: [NIOLockedValueBox<NodeHealth>] = []
        health.reserveCapacity(addressBook.count)
        
        var connections: [NodeConnection] = []
        connections.reserveCapacity(addressBook.count)

        for (index, address) in addressBook.enumerated() {
            // Use dictionary for O(1) port priority lookup instead of O(n) array search
            let endpoints = address.serviceEndpoints
                .sorted {
                    Self.portPriority[$0.port] ?? Int.max < Self.portPriority[$1.port] ?? Int.max
                }

            let selected = endpoints.first.flatMap { endpoint -> HostAndPort? in
                let host = endpoint.ip?.debugDescription ?? endpoint.domainName
                guard let resolvedHost = host, !resolvedHost.isEmpty else { return nil }
                return HostAndPort(host: resolvedHost, port: endpoint.port)
            }

            let new: Set<HostAndPort> = selected.map { Set([$0]) } ?? []

            let upsert: (NIOLockedValueBox<NodeHealth>, NodeConnection)

            switch old.nodeIndexMap[address.nodeAccountId] {
            case .some(let account):
                let connection: NodeConnection
                switch old.nodeConnections[account].addresses.symmetricDifference(new).count {
                case 0: connection = old.nodeConnections[account]
                case _: connection = NodeConnection(eventLoop: eventLoop, addresses: new)
                }

                upsert = (old.nodeHealthStates[account], connection)
            case nil: upsert = (.init(.unused), NodeConnection(eventLoop: eventLoop, addresses: new))
            }

            map[address.nodeAccountId] = index
            nodeIds.append(address.nodeAccountId)
            health.append(upsert.0)
            connections.append(upsert.1)
        }

        return Self(
            map: map,
            nodes: nodeIds,
            health: health,
            connections: connections
        )
    }

    /// Creates an updated network from address mappings, reusing existing connections where possible.
    ///
    /// - Parameters:
    ///   - old: The existing consensus network
    ///   - addresses: New address to account ID mappings
    ///   - eventLoop: Event loop for new connections
    /// - Returns: An updated consensus network
    internal static func withAddresses(_ old: ConsensusNetwork, addresses: [String: AccountId], eventLoop: EventLoop) throws
        -> Self
    {
        // Pre-allocate arrays to avoid reallocation during iteration
        var map: [AccountId: Int] = [:]
        map.reserveCapacity(addresses.count)
        
        var nodeIds: [AccountId] = []
        nodeIds.reserveCapacity(addresses.count)
        
        var health: [NIOLockedValueBox<NodeHealth>] = []
        health.reserveCapacity(addresses.count)
        
        var connections: [NodeConnection] = []
        connections.reserveCapacity(addresses.count)

        let addresses = Dictionary(
            try addresses.map { (key, value) throws -> (AccountId, Set<HostAndPort>) in
                let res = Set([try HostAndPort(parsing: key)])
                return (value, res)
            },
            uniquingKeysWith: { $0.union($1) }
        )

        for (node, addresses) in addresses {
            let nextIndex = nodeIds.count

            map[node] = nextIndex
            nodeIds.append(node)

            var reusedHealth: NIOLockedValueBox<NodeHealth>?
            var reusedConnection: NodeConnection?

            if let index = old.nodeIndexMap[node] {
                if old.nodeConnections[index].addresses.symmetricDifference(addresses).isEmpty {
                    reusedConnection = old.nodeConnections[index]
                }

                reusedHealth = old.nodeHealthStates[index]
            }

            health.append(reusedHealth ?? .init(.unused))
            connections.append(reusedConnection ?? .init(eventLoop: eventLoop, addresses: addresses))
        }

        return Self(
            map: map,
            nodes: nodeIds,
            health: health,
            connections: connections
        )
    }
    
    // MARK: - Channel Access
    
    /// Returns the channel and account ID for a node at the specified index.
    ///
    /// - Parameter nodeIndex: Index of the node in the nodes array
    /// - Returns: Tuple of (AccountId, GRPCChannel) for the node
    internal func channel(for nodeIndex: Int) -> (AccountId, GRPCChannel) {
        let accountId = nodes[nodeIndex]
        let channel = nodeConnections[nodeIndex].channel

        return (accountId, channel)
    }
    
    // MARK: - Node Selection
    
    /// Converts account IDs to their corresponding node indexes.
    ///
    /// - Parameter accountIds: Array of account IDs to look up
    /// - Returns: Array of node indexes
    /// - Throws: HError if any account ID is unknown
    internal func nodeIndexes(for accountIds: [AccountId]) throws -> [Int] {
        try accountIds.map { id in
            guard let index = nodeIndexMap[id] else {
                throw HError(kind: .nodeAccountUnknown, description: "Node account \(id) is unknown")
            }

            return index
        }
    }

    /// Returns indexes of all currently healthy nodes.
    internal func healthyNodeIndexes() -> [Int] {
        let now = Timestamp.now

        return (0..<nodeHealthStates.count).filter { isNodeHealthy(at: $0, now: now) }
    }

    /// Returns account IDs of all currently healthy nodes.
    internal func healthyNodeAccountIds() -> [AccountId] {
        healthyNodeIndexes().map { nodes[$0] }
    }

    /// Returns a random selection of healthy node account IDs (approximately 2/3).
    ///
    /// If no nodes are currently healthy, returns all nodes. This ensures requests
    /// can still be attempted even when health tracking indicates issues.
    ///
    /// - Note: Optimized to minimize allocations by working with indexes directly.
    internal func selectHealthyNodeSample() -> [AccountId] {
        let healthyIndexes = self.healthyNodeIndexes()
        
        // If no healthy nodes, sample from all nodes
        let sourceIndexes = healthyIndexes.isEmpty ? Array(0..<nodes.count) : healthyIndexes
        
        let sampleSize = (sourceIndexes.count + 2) / 3
        let selectedIndexes = randomIndexes(upTo: sourceIndexes.count, amount: sampleSize)
        
        // Map the sampled positions to actual node indexes, then to account IDs
        return selectedIndexes.map { nodes[sourceIndexes[$0]] }
    }
    
    // MARK: - Health Management
    
    /// Marks a node as unhealthy with exponential backoff.
    ///
    /// - Parameter index: Index of the node to mark unhealthy
    internal func markNodeUnhealthy(at index: Int) {
        nodeHealthStates[index].withLockedValue { $0.markUnhealthy(at: .now) }
    }

    /// Marks a node as healthy and resets its backoff timer.
    ///
    /// - Parameter index: Index of the node to mark healthy
    internal func markNodeHealthy(at index: Int) {
        nodeHealthStates[index].withLockedValue { $0.markHealthy(at: .now) }
    }

    /// Checks if a node was recently pinged (within the last 15 minutes).
    ///
    /// - Parameters:
    ///   - index: Index of the node to check
    ///   - now: Current timestamp
    /// - Returns: True if the node was recently pinged
    internal func nodeRecentlyPinged(at index: Int, now: Timestamp) -> Bool {
        nodeHealthStates[index].withLockedValue { $0 }.recentlyPinged(at: now)
    }

    /// Checks if a node is currently considered healthy.
    ///
    /// - Parameters:
    ///   - index: Index of the node to check
    ///   - now: Current timestamp
    /// - Returns: True if the node is healthy
    internal func isNodeHealthy(at index: Int, now: Timestamp) -> Bool {
        nodeHealthStates[index].withLockedValue { $0 }.isHealthy(at: now)
    }
}

// MARK: - Atomic Helpers

extension ManagedAtomic {
    /// Performs a read-copy-update operation atomically.
    ///
    /// This continuously retries until the update succeeds without interference from other threads.
    ///
    /// - Parameter body: Transformation function that creates the new value
    /// - Returns: The new value that was successfully stored
    internal func readCopyUpdate(_ body: (Value) throws -> Value) rethrows -> Value {
        while true {
            let old = load(ordering: .acquiring)
            let new = try body(old)
            let (success, _) = compareExchange(expected: old, desired: new, ordering: .acquiringAndReleasing)

            if success {
                return new
            }
        }
    }
}
