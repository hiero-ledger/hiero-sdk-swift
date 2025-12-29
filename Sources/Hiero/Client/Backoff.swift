// SPDX-License-Identifier: Apache-2.0

import Foundation

// MARK: - Client Backoff Configuration

/// Configuration for retry backoff behavior.
///
/// This structure defines the parameters for exponential backoff retry logic,
/// including timing constraints and maximum attempt limits.
///
/// ## Related Types
/// - `ExponentialBackoff` - The underlying backoff algorithm implementation
/// - `Client` - Uses this configuration for request retries
internal struct Backoff {
    // MARK: - Constants

    /// Default maximum number of retry attempts before giving up
    internal static let defaultMaxAttempts: Int = 10

    /// Default request timeout (2 minutes)
    internal static let defaultRequestTimeout: TimeInterval = 120.0

    // MARK: - Initialization

    /// Creates a new backoff configuration.
    ///
    /// - Parameters:
    ///   - maxBackoff: Maximum delay between retries (default: 60 seconds)
    ///   - initialBackoff: Initial delay for first retry (default: 0.5 seconds)
    ///   - maxAttempts: Maximum number of retry attempts (default: 10)
    ///   - requestTimeout: Overall timeout for the entire request including retries (default: 2 minutes)
    ///   - grpcTimeout: Timeout for individual GRPC calls (deprecated, use Client.grpcDeadline instead)
    internal init(
        maxBackoff: TimeInterval = ExponentialBackoff.defaultMaxInterval,
        initialBackoff: TimeInterval = ExponentialBackoff.defaultInitialInterval,
        maxAttempts: Int = Self.defaultMaxAttempts,
        requestTimeout: TimeInterval? = Self.defaultRequestTimeout,
        grpcTimeout: TimeInterval? = nil
    ) {
        self.maxBackoff = maxBackoff
        self.initialBackoff = initialBackoff
        self.maxAttempts = maxAttempts
        self.requestTimeout = requestTimeout
        self.grpcTimeout = grpcTimeout
    }

    // MARK: - Properties

    /// Maximum backoff delay between retries
    internal var maxBackoff: TimeInterval

    /// Initial backoff delay for first retry
    internal var initialBackoff: TimeInterval

    /// Maximum number of retry attempts
    internal var maxAttempts: Int

    /// Overall timeout for the entire request including retries (default: 2 minutes)
    internal var requestTimeout: TimeInterval?

    /// Timeout for individual GRPC calls (deprecated, use Client.grpcDeadline instead)
    internal var grpcTimeout: TimeInterval?
}
