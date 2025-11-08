// SPDX-License-Identifier: Apache-2.0

import GRPC
import NIOCore

// MARK: - Host And Port

/// Represents a network host and port combination for node connections.
///
/// This lightweight value type encapsulates a hostname/IP address and port number,
/// providing utilities for transport security configuration and string parsing.
/// Used throughout the network layer for both consensus and mirror node addressing.
///
/// ## Related Types
/// - `NodeConnection` - Uses HostAndPort for node addresses
/// - `MirrorNetwork` - Uses HostAndPort for mirror node endpoints
/// - `ChannelBalancer` - Connects to multiple HostAndPort targets
internal struct HostAndPort: Hashable, Equatable {
    // MARK: - Properties
    
    /// The hostname or IP address
    internal let host: String
    
    /// The port number
    internal let port: UInt16
    
    // MARK: - Transport Security
    
    /// Determines the appropriate transport security configuration based on port number.
    ///
    /// - Parameters:
    ///   - eventLoop: Event loop for TLS configuration
    ///   - mirrorPort: Whether to use mirror network port conventions (default: false)
    /// - Returns: Transport security configuration (TLS or plaintext)
    internal func transportSecurity(for eventLoop: EventLoop, mirrorPort: Bool = false)
        -> GRPCChannelPool.Configuration.TransportSecurity
    {
        let tlsPort = mirrorPort ? NodeConnection.mirrorTlsPort : NodeConnection.consensusTlsPort
        return port == tlsPort
            ? .tls(.makeClientDefault(compatibleWith: eventLoop))
            : .plaintext
    }
}

// MARK: - String Conversion

extension HostAndPort: LosslessStringConvertible {
    /// Creates a HostAndPort from a string like "host:port" or "host" (defaults to port 443).
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

    /// Creates a HostAndPort from a string, throwing an error if parsing fails.
    ///
    /// - Parameter description: String in "host:port" format
    /// - Throws: HError if the string cannot be parsed
    internal init<S: StringProtocol>(parsing description: S) throws {
        guard let tmp = Self(description) else {
            throw HError.basicParse("invalid URL")
        }

        self = tmp
    }

    /// Returns the string representation in "host:port" format.
    internal var description: String {
        "\(host):\(port)"
    }
}

