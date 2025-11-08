// SPDX-License-Identifier: Apache-2.0

import GRPC
import NIOCore
import SwiftProtobuf

// MARK: - Channel Balancer

/// Load balancer for GRPC channels using random selection strategy.
///
/// This balancer uses simple random selection for load distribution. While the
/// Power of Two Choices (P2C) algorithm would provide better distribution by
/// selecting the less-loaded of two random channels, implementing it requires
/// reliable metrics on in-flight requests, which the current GRPC API doesn't
/// easily provide.
///
/// ## Design Rationale
/// Random selection is sufficient for most use cases and avoids:
/// - Thundering herd problems of round-robin selection
/// - Complexity of maintaining accurate per-channel metrics
/// - Race conditions in concurrent request tracking
///
/// ## Related Types
/// - `NodeConnection` - Uses ChannelBalancer for node-level load balancing
/// - `MirrorNetwork` - Uses ChannelBalancer for mirror node distribution
///
/// - Warning: If a request to a non-existent host never returns, the system may hang.
///   Consider implementing timeout handling at a higher level.
internal final class ChannelBalancer: GRPCChannel {
    // MARK: - Properties

    /// The event loop for managing channel operations
    internal let eventLoop: EventLoop

    /// Pool of GRPC channels available for load balancing
    private let channels: [any GRPCChannel]

    // MARK: - Initialization

    /// Creates a new channel balancer with the specified target/security pairs.
    ///
    /// - Parameters:
    ///   - eventLoop: The event loop for channel operations
    ///   - targetSecurityPairs: Array of connection targets paired with their security configurations
    internal init(
        eventLoop: EventLoop,
        targetSecurityPairs: [(GRPC.ConnectionTarget, GRPCChannelPool.Configuration.TransportSecurity)]
    ) {
        self.eventLoop = eventLoop
        self.channels = targetSecurityPairs.map { (target, security) in
            try! GRPCChannelPool.with(target: target, transportSecurity: security, eventLoopGroup: eventLoop)
        }
    }

    // MARK: - GRPCChannel Protocol

    /// Creates a call using a randomly selected channel from the pool.
    internal func makeCall<Request, Response>(
        path: String,
        type: GRPC.GRPCCallType,
        callOptions: GRPC.CallOptions,
        interceptors: [GRPC.ClientInterceptor<Request, Response>]
    )
        -> GRPC.Call<Request, Response> where Request: GRPC.GRPCPayload, Response: GRPC.GRPCPayload
    {
        return selectChannel().makeCall(
            path: path,
            type: type,
            callOptions: callOptions,
            interceptors: interceptors
        )
    }

    /// Creates a call using a randomly selected channel from the pool.
    internal func makeCall<Request, Response>(
        path: String,
        type: GRPC.GRPCCallType,
        callOptions: GRPC.CallOptions,
        interceptors: [GRPC.ClientInterceptor<Request, Response>]
    ) -> GRPC.Call<Request, Response> where Request: SwiftProtobuf.Message, Response: SwiftProtobuf.Message {
        return selectChannel().makeCall(
            path: path,
            type: type,
            callOptions: callOptions,
            interceptors: interceptors
        )
    }

    /// Closes all channels in the pool.
    internal func close() -> NIOCore.EventLoopFuture<Void> {
        EventLoopFuture.reduce(
            into: (),
            channels.map { $0.close() },
            on: eventLoop
        ) { _, _ in }
    }

    // MARK: - Private Methods

    /// Randomly selects a channel from the pool for load balancing.
    ///
    /// - Returns: A randomly selected GRPC channel
    private func selectChannel() -> any GRPCChannel {
        channels.randomElement()!  // Safe: channels is non-empty (created in init)
    }
}
