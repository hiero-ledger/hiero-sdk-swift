// SPDX-License-Identifier: Apache-2.0

import Atomics
import GRPC
import NIOCore

// MARK: - Mirror Network

/// Manages connections to Hedera mirror nodes for querying historical data.
///
/// Mirror nodes provide access to transaction history, account balances, and other
/// data without requiring consensus. They're optimized for queries and can be load
/// balanced across multiple endpoints.
internal final class MirrorNetwork: AtomicReference, Sendable {
    // MARK: - Pre-configured Endpoints

    /// Standard mirror node endpoints for different Hedera networks
    private enum Endpoints {
        /// Mainnet mirror node endpoint
        static let mainnet: Set<HostAndPort> = [.init(host: "mainnet-public.mirrornode.hedera.com", port: 443)]

        /// Testnet mirror node endpoint
        static let testnet: Set<HostAndPort> = [.init(host: "testnet.mirrornode.hedera.com", port: 443)]

        /// Previewnet mirror node endpoint
        static let previewnet: Set<HostAndPort> = [.init(host: "previewnet.mirrornode.hedera.com", port: 443)]

        /// Localhost mirror node for development
        static let localhost: Set<HostAndPort> = [.init(host: "127.0.0.1", port: 5600)]
    }

    // MARK: - Properties

    /// Channel balancer for distributing requests across mirror node endpoints
    internal let channel: ChannelBalancer

    /// Set of all mirror node addresses
    internal let addresses: Set<HostAndPort>

    // MARK: - Initialization

    /// Primary designated initializer.
    ///
    /// - Parameters:
    ///   - channel: Pre-configured channel balancer
    ///   - targets: Set of host and port combinations for mirror nodes
    private init(channel: ChannelBalancer, targets: Set<HostAndPort>) {
        self.channel = channel
        self.addresses = targets
    }

    /// Creates a mirror network with TLS-secured connections (default for public mirror nodes).
    ///
    /// - Parameters:
    ///   - endpoints: Set of host and port combinations
    ///   - eventLoop: Event loop group for connections
    private convenience init(endpoints: Set<HostAndPort>, eventLoop: EventLoopGroup) {
        self.init(
            endpoints: endpoints,
            eventLoop: eventLoop,
            transportSecurity: .tls(
                .makeClientDefault(compatibleWith: eventLoop)
            )
        )
    }

    /// Creates a mirror network with specified transport security.
    ///
    /// - Parameters:
    ///   - endpoints: Set of host and port combinations
    ///   - eventLoop: Event loop group for connections
    ///   - transportSecurity: Transport security configuration (TLS or plaintext)
    private convenience init(
        endpoints: Set<HostAndPort>,
        eventLoop: EventLoopGroup,
        transportSecurity: GRPCChannelPool.Configuration.TransportSecurity
    ) {
        let targetSecurityPairs = endpoints.map { hostAndPort in
            let security = hostAndPort.transportSecurity(for: eventLoop.next(), mirrorPort: true)
            return (GRPC.ConnectionTarget.host(hostAndPort.host, port: Int(hostAndPort.port)), security)
        }

        self.init(
            channel: ChannelBalancer(
                eventLoop: eventLoop.next(),
                targetSecurityPairs: targetSecurityPairs
            ),
            targets: endpoints
        )
    }

    /// Creates a mirror network from an array of address strings (with TLS by default).
    ///
    /// - Parameters:
    ///   - targets: Array of address strings in "host:port" format
    ///   - eventLoop: Event loop group for connections
    internal convenience init(targets: [String], eventLoop: EventLoopGroup) {
        self.init(
            targets: targets, eventLoop: eventLoop,
            transportSecurity: .tls(.makeClientDefault(compatibleWith: eventLoop)))
    }

    /// Creates a mirror network from address strings with custom transport security.
    ///
    /// This initializer automatically detects localhost addresses and can use plaintext
    /// connections for them if specified in the transport security.
    ///
    /// - Parameters:
    ///   - targets: Array of address strings in "host:port" format
    ///   - eventLoop: Event loop group for connections
    ///   - transportSecurity: Transport security configuration (TLS or plaintext)
    internal convenience init(
        targets: [String],
        eventLoop: EventLoopGroup,
        transportSecurity: GRPCChannelPool.Configuration.TransportSecurity
    ) {
        // Parse address strings into HostAndPort structures
        let hostAndPorts = Set(
            targets.lazy.map { target in
                let (host, port) = target.splitOnce(on: ":") ?? (target[...], nil)
                return HostAndPort(
                    host: String(host), port: port.flatMap { UInt16($0) } ?? NodeConnection.mirrorTlsPort)
            }
        )

        // Check if all targets are localhost (use plaintext for local development)
        let isLocal = targets.allSatisfy {
            $0.contains("localhost") || $0.contains("127.0.0.1")
        }

        let mirrorChannel = ChannelBalancer(
            eventLoop: eventLoop.next(),
            targetSecurityPairs: hostAndPorts.map {
                let security: GRPCChannelPool.Configuration.TransportSecurity =
                    isLocal
                    ? .plaintext
                    : .tls(.makeClientDefault(compatibleWith: eventLoop))

                return (.host($0.host, port: Int($0.port)), security)
            }
        )

        self.init(channel: mirrorChannel, targets: hostAndPorts)
    }

    // MARK: - Factory Methods

    /// Creates a mirror network pre-configured for Hedera mainnet.
    ///
    /// - Parameter eventLoop: Event loop group for connections
    /// - Returns: A mirror network connected to mainnet mirror nodes
    internal static func mainnet(_ eventLoop: NIOCore.EventLoopGroup) -> Self {
        Self(endpoints: Endpoints.mainnet, eventLoop: eventLoop)
    }

    /// Creates a mirror network pre-configured for Hedera testnet.
    ///
    /// - Parameter eventLoop: Event loop group for connections
    /// - Returns: A mirror network connected to testnet mirror nodes
    internal static func testnet(_ eventLoop: NIOCore.EventLoopGroup) -> Self {
        Self(endpoints: Endpoints.testnet, eventLoop: eventLoop)
    }

    /// Creates a mirror network pre-configured for Hedera previewnet.
    ///
    /// - Parameter eventLoop: Event loop group for connections
    /// - Returns: A mirror network connected to previewnet mirror nodes
    internal static func previewnet(_ eventLoop: NIOCore.EventLoopGroup) -> Self {
        Self(endpoints: Endpoints.previewnet, eventLoop: eventLoop)
    }

    /// Creates a mirror network pre-configured for localhost development.
    ///
    /// Uses plaintext connection on port 5600 for local mirror node instances.
    ///
    /// - Parameter eventLoop: Event loop group for connections
    /// - Returns: A mirror network connected to localhost mirror node
    internal static func localhost(_ eventLoop: NIOCore.EventLoopGroup) -> Self {
        let targetSecurityPairs = Endpoints.localhost.map { hostAndPort in
            let security = hostAndPort.transportSecurity(for: eventLoop.next(), mirrorPort: true)
            return (GRPC.ConnectionTarget.host(hostAndPort.host, port: Int(hostAndPort.port)), security)
        }

        return Self(
            channel: ChannelBalancer(
                eventLoop: eventLoop.next(),
                targetSecurityPairs: targetSecurityPairs
            ),
            targets: Endpoints.localhost
        )
    }
}
