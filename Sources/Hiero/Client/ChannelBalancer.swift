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
/// ## Timeout Handling
/// Per-request gRPC timeouts are enforced at the execution layer via `CallOptions.timeLimit`,
/// configured using the client's `grpcDeadline` setting (default: 10 seconds). This provides
/// finer-grained timeout control for individual gRPC calls.
///
/// When a gRPC request exceeds the deadline:
/// - The SDK aborts the request
/// - Marks the node as temporarily unhealthy
/// - Rotates to the next healthy node automatically
///
/// Additionally, overall operation timeouts are managed via `ExponentialBackoff.maxElapsedTime`
/// and `Backoff.requestTimeout` (default: 2 minutes), which prevent indefinite hangs during retries.
///
/// ## Related Types
/// - `NodeConnection` - Uses ChannelBalancer for node-level load balancing
/// - `MirrorNetwork` - Uses ChannelBalancer for mirror node distribution
/// - `Client` - Contains `grpcDeadline` and `requestTimeout` configuration
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
    ///
    /// - Precondition: GRPC channel pool creation must succeed. If it fails, this is a
    ///   programming error and the application should crash rather than continue with invalid state.
    internal init(
        eventLoop: EventLoop,
        targetSecurityPairs: [(GRPC.ConnectionTarget, GRPCChannelPool.Configuration.TransportSecurity)]
    ) {
        self.eventLoop = eventLoop
        self.channels = targetSecurityPairs.map { (target, security) in
            // Crash intentionally if channel creation fails - no recovery possible at initialization
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
