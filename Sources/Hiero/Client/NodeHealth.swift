// SPDX-License-Identifier: Apache-2.0

import Foundation

// MARK: - Node Health

/// Represents the health status of a consensus node using a circuit breaker pattern.
///
/// Nodes transition between four states:
/// - `unused`: Never contacted, assumed healthy
/// - `healthy`: Recently succeeded, cached for 15 minutes
/// - `unhealthy`: Recently failed, with exponential backoff before retry
/// - `circuitOpen`: Persistently failing, temporarily excluded from use
///
/// ## Circuit Breaker Pattern
/// The circuit breaker prevents wasted retries on nodes that are consistently failing
/// by transitioning to `circuitOpen` after multiple consecutive failures (5 by default).
/// After a recovery period (5 minutes), the circuit transitions to half-open (unhealthy
/// with minimal backoff) to test if the node has recovered.
///
/// ## State Diagram
/// ```
/// unused → healthy ↔ unhealthy → circuitOpen
///            ↑          ↓              ↓
///            └──────────┴──────────────┘
/// ```
///
/// ## Related Types
/// - `ExponentialBackoff` - Calculates backoff intervals for unhealthy state
/// - `ConsensusNetwork` - Tracks health for all consensus nodes
internal enum NodeHealth: Sendable {
    /// The node has never been used, so health is unknown but assumed good.
    case unused

    /// The node recently succeeded and can be used freely for 15 minutes.
    case healthy(usedAt: Timestamp)

    /// The node recently encountered errors and should be avoided temporarily.
    ///
    /// The backoff interval increases exponentially with repeated failures,
    /// and the node becomes eligible for retry after `healthyAt`.
    /// Tracks consecutive failures to detect persistent issues.
    case unhealthy(backoffInterval: TimeInterval, healthyAt: Timestamp, consecutiveFailures: Int)

    /// The node has failed persistently and is temporarily excluded from use.
    ///
    /// After the recovery period expires, the circuit transitions to half-open
    /// (unhealthy state with minimal backoff) to test recovery.
    case circuitOpen(reopenAt: Timestamp)

    // MARK: - Constants

    /// Maximum consecutive failures before opening the circuit (5 failures)
    private static let maxConsecutiveFailures = 5

    /// Duration to keep circuit open before testing recovery (5 minutes in nanoseconds)
    private static let circuitOpenDurationNanos: UInt64 = 5 * 60 * 1_000_000_000

    /// Initial backoff interval for first failure (250 milliseconds)
    private static let initialBackoffInterval: TimeInterval = 0.25

    /// Maximum backoff interval before circuit opens (30 minutes)
    private static let maxBackoffInterval: TimeInterval = 30 * 60

    /// Duration to cache healthy node status (15 minutes in nanoseconds)
    private static let healthyCacheDurationNanos: UInt64 = 15 * 60 * 1_000_000_000

    // MARK: - Computed Properties

    /// The exponential backoff configuration for this node.
    ///
    /// Backoff intervals range from 250ms to 30 minutes, with no maximum elapsed time.
    internal var backoff: ExponentialBackoff {
        var backoff = ExponentialBackoff(
            initialInterval: Self.initialBackoffInterval,
            maxInterval: Self.maxBackoffInterval,
            maxElapsedTime: .unlimited
        )

        if case .unhealthy(let backoffInterval, _, _) = self {
            backoff.currentInterval = backoffInterval
        }

        return backoff
    }

    // MARK: - State Transitions

    /// Marks the node as unhealthy and calculates the next backoff interval.
    ///
    /// Implements circuit breaker logic:
    /// - Increments consecutive failure count
    /// - Opens circuit after reaching max consecutive failures
    /// - Otherwise, applies exponential backoff
    ///
    /// - Parameter now: Current timestamp
    internal mutating func markUnhealthy(at now: Timestamp) {
        let consecutiveFailures: Int

        switch self {
        case .unhealthy(_, _, let failures):
            consecutiveFailures = failures + 1
        case .circuitOpen:
            // Circuit already open, no state change needed
            return
        default:
            consecutiveFailures = 1
        }

        // Open circuit after too many consecutive failures
        if consecutiveFailures >= Self.maxConsecutiveFailures {
            let reopenAt = now.adding(nanos: Self.circuitOpenDurationNanos)
            self = .circuitOpen(reopenAt: reopenAt)
            return
        }

        // Apply exponential backoff
        var backoff = self.backoff
        let backoffInterval = backoff.next()!
        let healthyAt = now.adding(nanos: UInt64(backoffInterval * 1_000_000_000))

        self = .unhealthy(
            backoffInterval: backoffInterval,
            healthyAt: healthyAt,
            consecutiveFailures: consecutiveFailures
        )
    }

    /// Marks the node as healthy and resets all failure tracking.
    ///
    /// This closes any open circuit and resets consecutive failure counts.
    ///
    /// - Parameter now: Current timestamp
    internal mutating func markHealthy(at now: Timestamp) {
        self = .healthy(usedAt: now)
    }

    // MARK: - Health Checks

    /// Checks if the node is currently considered healthy and available for use.
    ///
    /// A node is healthy if:
    /// - It's unused (never contacted)
    /// - It's in the healthy state
    /// - It's unhealthy but the backoff period has elapsed
    /// - It's circuit-open but the recovery period has elapsed (transitions to half-open)
    ///
    /// - Parameter now: Current timestamp
    /// - Returns: True if the node is healthy and available
    internal func isHealthy(at now: Timestamp) -> Bool {
        switch self {
        case .unused, .healthy:
            return true

        case .unhealthy(_, let healthyAt, _):
            return now >= healthyAt

        case .circuitOpen(let reopenAt):
            // Circuit transitions to half-open when recovery period expires
            return now >= reopenAt
        }
    }

    /// Checks if the node was recently pinged or contacted.
    ///
    /// Used to avoid redundant health checks on nodes that were recently verified.
    ///
    /// - Parameter now: Current timestamp
    /// - Returns: True if the node was recently contacted
    internal func recentlyPinged(at now: Timestamp) -> Bool {
        switch self {
        case .healthy(let usedAt):
            // Healthy nodes are cached for the configured duration
            return now < usedAt.adding(nanos: Self.healthyCacheDurationNanos)

        case .unhealthy(_, let healthyAt, _):
            // Unhealthy nodes are avoided until backoff expires
            return now < healthyAt

        case .circuitOpen(let reopenAt):
            // Open circuits are avoided until recovery period expires
            return now < reopenAt

        case .unused:
            return false
        }
    }
}
