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
    // MARK: - Initialization
    
    /// Creates a new backoff configuration.
    ///
    /// - Parameters:
    ///   - maxBackoff: Maximum delay between retries
    ///   - initialBackoff: Initial delay for first retry
    ///   - maxAttempts: Maximum number of retry attempts
    ///   - requestTimeout: Overall timeout for the entire request
    ///   - grpcTimeout: Timeout for individual GRPC calls (currently unused)
    internal init(
        maxBackoff: TimeInterval = ExponentialBackoff.defaultMaxInterval,
        initialBackoff: TimeInterval = ExponentialBackoff.defaultInitialInterval,
        maxAttempts: Int = 10,
        requestTimeout: TimeInterval? = nil,
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

    /// Overall timeout for the entire request including retries
    internal var requestTimeout: TimeInterval?

    /// Timeout for individual GRPC calls (currently unused)
    internal var grpcTimeout: TimeInterval?
}
