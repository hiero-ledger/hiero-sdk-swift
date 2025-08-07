// SPDX-License-Identifier: Apache-2.0

import Atomics
import Foundation
import GRPC
import NIOConcurrencyHelpers
import NIOCore
import SwiftProtobuf

// Note: Ideally this would use some form of algorithm to balance better (IE P2C, but how do you check connection metrics?)
// Random is surprisingly good at this though (avoids the thundering herd that would happen if round-robin was used), so...
internal final class ChannelBalancer: GRPCChannel {
    internal let eventLoop: EventLoop
    private let channels: [any GRPCChannel]
    private let targets: [GRPC.ConnectionTarget]

    // fixme: if the request never returns (IE the host doesn't exist) we kinda just, get stuck
    internal init(
        eventLoop: EventLoop,
        _ targetSecurityPairs: [(GRPC.ConnectionTarget, GRPCChannelPool.Configuration.TransportSecurity)]
    ) {
        self.eventLoop = eventLoop
        self.targets = targetSecurityPairs.map { $0.0 }

        self.channels = targetSecurityPairs.map { (target, security) in
            try! GRPCChannelPool.with(target: target, transportSecurity: security, eventLoopGroup: eventLoop)
        }
    }

    internal func makeCall<Request, Response>(
        path: String,
        type: GRPC.GRPCCallType,
        callOptions: GRPC.CallOptions,
        interceptors: [GRPC.ClientInterceptor<Request, Response>]
    )
        -> GRPC.Call<Request, Response> where Request: GRPC.GRPCPayload, Response: GRPC.GRPCPayload
    {
        let elem = channels.randomElement()!

        let res = elem.makeCall(path: path, type: type, callOptions: callOptions, interceptors: interceptors)

        return res
    }

    internal func makeCall<Request, Response>(
        path: String,
        type: GRPC.GRPCCallType,
        callOptions: GRPC.CallOptions,
        interceptors: [GRPC.ClientInterceptor<Request, Response>]
    ) -> GRPC.Call<Request, Response> where Request: SwiftProtobuf.Message, Response: SwiftProtobuf.Message {
        let elem = channels.randomElement()!

        let res = elem.makeCall(path: path, type: type, callOptions: callOptions, interceptors: interceptors)

        return res
    }

    // todo: have someone look at this.
    internal func close() -> NIOCore.EventLoopFuture<Void> {
        return EventLoopFuture.reduce(into: (), channels.map { $0.close() }, on: eventLoop, { (_, _) in })
    }
}

internal final class Network: Sendable, AtomicReference {
    private init(
        map: [AccountId: Int],
        nodes: [AccountId],
        health: [NIOLockedValueBox<NodeHealth>],
        connections: [NodeConnection]
    ) {
        self.map = map
        self.nodes = nodes
        self.health = health
        self.connections = connections
    }

    internal let map: [AccountId: Int]
    internal let nodes: [AccountId]
    // locked-value-box is a reference type, which we need.
    fileprivate let health: [NIOLockedValueBox<NodeHealth>]
    fileprivate let connections: [NodeConnection]

    internal var addresses: [String: AccountId] {
        Dictionary(
            map.lazy.flatMap { (account, index) in
                self.connections[index].addresses.lazy.map { (String(describing: $0), account) }
            },
            uniquingKeysWith: { first, _ in first }
        )
    }

    fileprivate convenience init(config: Config, eventLoop: NIOCore.EventLoopGroup) {
        // todo: someone verify this code pls.
        let connections = config.addresses.map { addresses in
            let addresses = Set(addresses.map { HostAndPort(host: $0, port: 50211) })
            return NodeConnection(eventLoop: eventLoop.next(), addresses: addresses)
        }

        // note: `Array(repeating: <element>, count: Int)` does *not* work the way you'd want with reference types.
        let health: [NIOLockedValueBox<NodeHealth>] = (0..<config.nodes.count).map { _ in .init(.unused) }

        self.init(
            map: config.map,
            nodes: config.nodes,
            health: health,
            connections: connections
        )
    }

    internal convenience init(addresses: [String: AccountId], eventLoop: EventLoop) throws {
        let tmp = try Self.withAddresses(
            Self(map: [:], nodes: [], health: [], connections: []), addresses, eventLoop: eventLoop)
        self.init(map: tmp.map, nodes: tmp.nodes, health: tmp.health, connections: tmp.connections)
    }

    internal static func addressBookToNetwork(_ addressBook: [NodeAddress]) -> [String: AccountId] {
        var network = [String: AccountId]()

        for nodeAddress in addressBook {
            for endpoint in nodeAddress.serviceEndpoints {
                network[endpoint.description] = nodeAddress.nodeAccountId
            }
        }

        return network
    }

    internal static func withAddressBook(_ old: Network, _ eventLoop: EventLoop, _ addressBook: NodeAddressBook) -> Self
    {
        let addressBook = addressBook.nodeAddresses

        var map: [AccountId: Int] = [:]
        var nodeIds: [AccountId] = []
        var health: [NIOLockedValueBox<NodeHealth>] = []
        var connections: [NodeConnection] = []

        for (index, address) in addressBook.enumerated() {
            let preferredPorts: [UInt16] = [NodeConnection.consensusTlsPort, NodeConnection.consensusPlaintextPort]

            let endpoints = address.serviceEndpoints
                .sorted {
                    preferredPorts.firstIndex(of: $0.port) ?? Int.max < preferredPorts.firstIndex(of: $1.port)
                        ?? Int.max
                }

            let selected = endpoints.first.flatMap { endpoint -> HostAndPort? in
                let host = endpoint.ip?.debugDescription ?? endpoint.domainName
                guard let resolvedHost = host, !resolvedHost.isEmpty else { return nil }
                return HostAndPort(host: resolvedHost, port: endpoint.port)
            }

            let new: Set<HostAndPort> = selected.map { Set([$0]) } ?? []

            // if the node is the exact same we want to reuse everything (namely the connections and `healthy`).
            // if the node has different routes then we still want to reuse `healthy` but replace the channel with a new channel.
            // if the node just flat out doesn't exist in `old`, we want to add the new node.
            // and, last but not least, if the node doesn't exist in `new` we want to get rid of it.

            let upsert: (NIOLockedValueBox<NodeHealth>, NodeConnection)

            switch old.map[address.nodeAccountId] {
            case .some(let account):
                let connection: NodeConnection
                switch old.connections[account].addresses.symmetricDifference(new).count {
                case 0: connection = old.connections[account]
                case _: connection = NodeConnection(eventLoop: eventLoop, addresses: new)
                }

                upsert = (old.health[account], connection)
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

    internal static func withAddresses(_ old: Network, _ addresses: [String: AccountId], eventLoop: EventLoop) throws
        -> Self
    {
        var map: [AccountId: Int] = [:]
        var nodeIds: [AccountId] = []
        var health: [NIOLockedValueBox<NodeHealth>] = []
        var connections: [NodeConnection] = []

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

            if let index = old.map[node] {
                if old.connections[index].addresses.symmetricDifference(addresses).isEmpty {
                    reusedConnection = old.connections[index]
                }

                reusedHealth = old.health[index]
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

    internal static func mainnet(_ eventLoop: NIOCore.EventLoopGroup) -> Self {
        Self(config: Config.mainnet, eventLoop: eventLoop)
    }

    internal static func testnet(_ eventLoop: NIOCore.EventLoopGroup) -> Self {
        Self(config: Config.testnet, eventLoop: eventLoop)
    }

    internal static func previewnet(_ eventLoop: NIOCore.EventLoopGroup) -> Self {
        Self(config: Config.previewnet, eventLoop: eventLoop)
    }

    internal func channel(for nodeIndex: Int) -> (AccountId, GRPCChannel) {
        let accountId = nodes[nodeIndex]
        let channel = connections[nodeIndex].channel

        return (accountId, channel)
    }

    internal func nodeIndexesForIds(_ nodeAccountIds: [AccountId]) throws -> [Int] {
        try nodeAccountIds.map { id in
            guard let index = map[id] else {
                throw HError(kind: .nodeAccountUnknown, description: "Node account \(id) is unknown")
            }

            return index
        }
    }

    internal func healthyNodeIndexes() -> [Int] {
        let now = Timestamp.now

        return (0..<health.count).filter { isNodeHealthy($0, now) }
    }

    internal func healthyNodeIds() -> [AccountId] {
        healthyNodeIndexes().map { nodes[$0] }
    }

    internal func markNodeUnhealthy(_ index: Int) {
        health[index].withLockedValue { $0.markUnhealthy(now: .now) }
    }

    internal func markNodeHealthy(_ index: Int) {
        health[index].withLockedValue { $0.markHealthy(now: .now) }
    }

    internal func nodeRecentlyPinged(_ index: Int, now: Timestamp) -> Bool {
        // use the lock to *just* read the state, since we aren't updating it.
        health[index].withLockedValue { $0 }.recentlyPinged(now: now)
    }

    internal func isNodeHealthy(_ index: Int, _ now: Timestamp) -> Bool {
        // use the lock to *just* read the state, since we aren't updating it.
        health[index].withLockedValue { $0 }.isHealthy(now: now)
    }

    internal func randomNodeIds()
        -> [AccountId]
    {
        var nodeIds = self.healthyNodeIds()

        if nodeIds.isEmpty {
            nodeIds = self.nodes
        }

        let nodeSampleAmount = (nodeIds.count + 2) / 3

        let nodeIdIndecies = randomIndexes(upTo: nodeIds.count, amount: nodeSampleAmount)

        return nodeIdIndecies.map { nodeIds[$0] }
    }
}

internal enum NodeHealth: Sendable {
    /// The node has never been used, so we don't know anything about it.
    ///
    /// However, we'll vaguely consider it healthy (`isHealthy` returns `true`).
    case unused

    /// When we used or pinged the node we got some kind of error with it (like a BUSY response).
    ///
    /// Repeated errors cause the backoff to increase.
    ///
    /// Once we've reached `healthyAt` the node is *semantically* in the ``unused`` state,
    /// other than retaining the backoff until a `healthy` request happens.
    case unhealthy(backoffInterval: TimeInterval, healthyAt: Timestamp)

    /// When we last used the node the node acted as normal, so, we get to treat it as a healthy node for 15 minutes.
    case healthy(usedAt: Timestamp)

    // note: this is a computed property rather than a stored one.
    // we compute it because:
    // A: it's a large struct.
    // B: we only really need it when we're marking ourselves as `unhealthy` which shouldn't be such a common operation that it's happening every few ms on the same node.
    internal var backoff: LegacyExponentialBackoff {
        var backoff = LegacyExponentialBackoff(
            initialInterval: 0.25,
            maxInterval: 30 * 60,
            maxElapsedTime: .unlimited
        )

        if case .unhealthy(let backoffInterval, _) = self {
            backoff.currentInterval = backoffInterval
        }

        return backoff
    }

    internal mutating func markUnhealthy(now: Timestamp) {
        var backoff = self.backoff
        let backoffInterval = backoff.next()!

        let healthyAt = now.adding(nanos: UInt64(backoffInterval * 1e9))

        self = .unhealthy(backoffInterval: backoffInterval, healthyAt: healthyAt)
    }

    internal mutating func markHealthy(now: Timestamp) {
        self = .healthy(usedAt: now)
    }

    internal func isHealthy(now: Timestamp) -> Bool {
        // a healthy node is any node that isn't *unhealthy*...
        guard case .unhealthy(_, let healthyAt) = self else {
            return true
        }

        // Which includes when the node *was* unhealthy but isn't anymore.
        return healthyAt < now
    }

    internal func recentlyPinged(now: Timestamp) -> Bool {
        switch self {
        // when used at was less than 15 minutes ago we consider ourselves "pinged", otherwise we're basically `.unused`.
        case .healthy(let usedAt): return now < usedAt + .minutes(15)
        // likewise an unhealthy node (healthyAt > now) has been "pinged" (although we don't want to use it probably we at least *have* gotten *something* from it)
        case .unhealthy(_, let healthyAt): return now < healthyAt

        // an unused node is by definition not pinged.
        case .unused: return false
        }
    }
}

internal struct HostAndPort: Hashable, Equatable {
    internal let host: String
    internal let port: UInt16
}

extension HostAndPort: LosslessStringConvertible {
    internal init?<S: StringProtocol>(_ description: S) {
        let (host, port) = description.splitOnce(on: ":") ?? (description[...], nil)

        guard let port = port else {
            self = .init(host: String(host), port: 443)
            return
        }

        guard let port = UInt16(port) else {
            return nil
        }

        self = .init(host: String(host), port: port)
    }

    internal init<S: StringProtocol>(parsing description: S) throws {
        guard let tmp = Self(description) else {
            throw HError.basicParse("invalid URL")
        }

        self = tmp
    }

    internal var description: String {
        "\(host):\(port)"
    }

}

internal struct NodeConnection: Sendable {
    internal init(eventLoop: EventLoop, addresses: Set<HostAndPort>) {
        realChannel = ChannelBalancer(
            eventLoop: eventLoop,
            addresses.map { address in
                let security: GRPCChannelPool.Configuration.TransportSecurity =
                    (address.port == NodeConnection.consensusTlsPort)
                    ? .tls(.makeClientDefault(compatibleWith: eventLoop)) : .plaintext
                return (GRPC.ConnectionTarget.host(address.host, port: Int(address.port)), security)
            }
        )

        self.addresses = addresses
    }

    internal let addresses: Set<HostAndPort>
    private let realChannel: ChannelBalancer

    internal var channel: any GRPCChannel {
        realChannel
    }

    internal static let consensusPlaintextPort: UInt16 = 50211
    internal static let consensusTlsPort: UInt16 = 50212
    internal static let mirrorPlaintextPort: UInt16 = 5600
    internal static let mirrorTlsPort: UInt16 = 443
}
