// SPDX-License-Identifier: Apache-2.0

import GRPC
import NIOCore

// MARK: - Node Connection

/// Manages GRPC connections to a single consensus node.
///
/// A node may have multiple addresses for redundancy, and the connection
/// uses a channel balancer to distribute requests across them. This struct
/// also defines standard port numbers for both consensus and mirror node communications.
///
/// ## Related Types
/// - `ChannelBalancer` - Handles load balancing across multiple addresses
/// - `ConsensusNetwork` - Maintains a collection of NodeConnection instances
/// - `HostAndPort` - Represents individual node addresses
internal struct NodeConnection: Sendable {
    // MARK: - Standard Ports
    
    /// Standard consensus node plaintext port
    internal static let consensusPlaintextPort: UInt16 = 50211
    
    /// Standard consensus node TLS port
    internal static let consensusTlsPort: UInt16 = 50212
    
    /// Standard mirror node plaintext port
    internal static let mirrorPlaintextPort: UInt16 = 5600
    
    /// Standard mirror node TLS port
    internal static let mirrorTlsPort: UInt16 = 443
    
    // MARK: - Properties
    
    /// All addresses for this node
    internal let addresses: Set<HostAndPort>
    
    /// The GRPC channel for this node's connections
    internal let channel: ChannelBalancer
    
    // MARK: - Initialization
    
    /// Creates a new node connection with the specified addresses.
    ///
    /// - Parameters:
    ///   - eventLoop: Event loop for channel operations
    ///   - addresses: Set of host and port combinations for this node
    internal init(eventLoop: EventLoop, addresses: Set<HostAndPort>) {
        self.channel = ChannelBalancer(
            eventLoop: eventLoop,
            targetSecurityPairs: addresses.map { address in
                let security = address.transportSecurity(for: eventLoop, mirrorPort: false)
                return (GRPC.ConnectionTarget.host(address.host, port: Int(address.port)), security)
            }
        )
        self.addresses = addresses
    }
}

