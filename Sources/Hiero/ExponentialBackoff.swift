// SPDX-License-Identifier: Apache-2.0

import Foundation

// MARK: - Exponential Backoff

/// Implements exponential backoff with randomization for retry logic.
///
/// This implementation provides a stateful exponential backoff calculator that increases
/// delay intervals between retries using a configurable multiplier. It includes:
/// - Randomization to avoid thundering herd problems
/// - Maximum elapsed time limits to prevent infinite retries
/// - Configurable intervals and multipliers
///
/// The backoff interval grows exponentially: initial → initial×multiplier → initial×multiplier² → ...
/// up to `maxInterval`. Each interval is randomized within a range to distribute load.
///
/// ## Note
/// This implementation exists because GRPC's `ConnectionBackoff` doesn't support `maxElapsedTime`.
/// On newer macOS versions, the `Clock` protocol could be used as an alternative.
///
/// Adapted from the Rust [`backoff`](https://github.com/ihrwein/backoff) crate,
/// licensed under MIT/Apache 2.0.
internal struct ExponentialBackoff {
    // MARK: - Nested Types

    /// Represents an optional time limit for backoff operations.
    ///
    /// Used to specify whether retries should continue indefinitely or stop after a maximum duration.
    internal enum Limit<T> {
        /// No time limit; retries continue indefinitely
        case unlimited

        /// Stop retrying after the specified duration
        case limited(T)

        /// Checks if the elapsed time has exceeded this limit.
        ///
        /// - Parameter elapsed: The elapsed time to check
        /// - Returns: `true` if the limit has been exceeded, `false` if unlimited or not yet exceeded
        internal func hasExpired(_ elapsed: T) -> Bool where T: Comparable {
            guard case .limited(let maxElapsed) = self else {
                return false  // unlimited never expires
            }
            return elapsed > maxElapsed
        }
    }

    // MARK: - Default Values

    /// Default maximum elapsed time before giving up (15 minutes)
    internal static let defaultMaxElapsedTime: TimeInterval = 900

    /// Default initial backoff interval (0.5 seconds)
    internal static let defaultInitialInterval: TimeInterval = 0.5

    /// Default maximum backoff interval (60 seconds)
    internal static let defaultMaxInterval: TimeInterval = 60

    // MARK: - Configuration Properties

    /// Initial backoff interval in seconds
    internal let initialInterval: TimeInterval

    /// Factor for randomizing intervals (0.0 to 1.0)
    ///
    /// A factor of 0.5 means the actual interval can vary from 50% to 150% of the calculated value.
    /// This randomization helps prevent multiple clients from retrying simultaneously.
    internal let randomizationFactor: Double

    /// Multiplier for increasing the interval on each retry
    ///
    /// Each subsequent retry interval is multiplied by this value until reaching `maxInterval`.
    /// A value of 1.5 means each retry waits 50% longer than the previous one.
    internal let multiplier: Double

    /// Maximum backoff interval in seconds
    ///
    /// The backoff interval will not grow beyond this value, even with continued retries.
    internal let maxInterval: TimeInterval

    /// Maximum total elapsed time before giving up
    ///
    /// When set to `.limited`, retries stop once this duration has elapsed since `startTime`.
    /// When set to `.unlimited`, retries continue indefinitely.
    internal let maxElapsedTime: Limit<TimeInterval>

    // MARK: - Mutable State

    /// Current backoff interval in seconds
    ///
    /// This value grows exponentially with each call to `next()`, up to `maxInterval`.
    internal var currentInterval: TimeInterval

    /// Timestamp when this backoff sequence started
    ///
    /// Used to calculate elapsed time and determine if `maxElapsedTime` has been exceeded.
    internal var startTime: Date

    // MARK: - Initialization

    /// Creates a new exponential backoff calculator.
    ///
    /// - Parameters:
    ///   - initialInterval: Starting backoff interval (default: 0.5 seconds)
    ///   - randomizationFactor: Randomization range as a factor (default: 0.5)
    ///   - multiplier: Growth factor for each retry (default: 1.5)
    ///   - maxInterval: Maximum backoff interval (default: 60 seconds)
    ///   - maxElapsedTime: Total timeout for retries (default: 15 minutes)
    ///   - startTime: Starting timestamp (default: now)
    internal init(
        initialInterval: TimeInterval = defaultInitialInterval,
        randomizationFactor: Double = 0.5,
        multiplier: Double = 1.5,
        maxInterval: TimeInterval = defaultMaxInterval,
        maxElapsedTime: Limit<TimeInterval> = .limited(defaultMaxElapsedTime),
        startTime: Date = Date()
    ) {
        self.initialInterval = initialInterval
        self.randomizationFactor = randomizationFactor
        self.multiplier = multiplier
        self.maxInterval = maxInterval
        self.maxElapsedTime = maxElapsedTime
        self.startTime = startTime
        self.currentInterval = initialInterval
    }

    // MARK: - Computed Properties

    /// The amount of time elapsed since this backoff sequence started.
    ///
    /// This value increases with each call and is used to determine if `maxElapsedTime` has been exceeded.
    internal var elapsedTime: TimeInterval {
        startTime.distance(to: Date())
    }

    // MARK: - Public Methods

    /// Calculates the next backoff interval.
    ///
    /// This method:
    /// 1. Checks if the maximum elapsed time has been exceeded
    /// 2. Calculates a randomized interval based on the current interval
    /// 3. Increments the current interval for the next call
    /// 4. Ensures the delay won't exceed the maximum elapsed time
    ///
    /// - Returns: The next backoff interval in seconds, or `nil` if max elapsed time exceeded
    internal mutating func next() -> TimeInterval? {
        let elapsed = self.elapsedTime

        // Check if we've exceeded the maximum elapsed time
        if maxElapsedTime.hasExpired(elapsed) {
            return nil
        }

        // Calculate randomized backoff interval
        let randomValue = Double.random(in: 0..<1)
        let interval = Self.calculateRandomizedInterval(
            currentInterval: currentInterval,
            randomizationFactor: randomizationFactor,
            randomValue: randomValue
        )

        // Prepare for next iteration by incrementing the interval
        incrementCurrentInterval()

        // If the calculated interval would push us over the time limit, stop now
        if maxElapsedTime.hasExpired(elapsed + interval) {
            return nil
        }

        return interval
    }

    /// Resets the backoff state to start a new retry sequence.
    ///
    /// This resets both the current interval to the initial value and the start time to now.
    /// Use this when beginning a new independent operation that needs its own backoff sequence.
    internal mutating func reset() {
        startTime = Date()
        currentInterval = initialInterval
    }

    // MARK: - Private Methods

    /// Calculates a randomized interval within a range around the current interval.
    ///
    /// The randomization helps prevent the "thundering herd" problem where multiple
    /// clients retry at exactly the same time.
    ///
    /// For example, with a current interval of 10s and randomization factor of 0.5:
    /// - Delta = 5s
    /// - Range = [5s, 15s]
    /// - Returns a random value in that range
    ///
    /// - Parameters:
    ///   - currentInterval: The base interval to randomize
    ///   - randomizationFactor: How much to vary (0.0 to 1.0)
    ///   - randomValue: Random value from 0.0 to 1.0
    /// - Returns: Randomized interval in seconds
    private static func calculateRandomizedInterval(
        currentInterval: TimeInterval,
        randomizationFactor: Double,
        randomValue: Double
    ) -> TimeInterval {
        let delta = randomizationFactor * currentInterval
        let minInterval = currentInterval - delta
        let maxInterval = currentInterval + delta

        // Calculate a random value from the range [minInterval, maxInterval]
        // Add epsilon to ensure maxInterval is included in the range
        let range = maxInterval - minInterval
        return minInterval + (randomValue * (range + 1e-9))
    }

    /// Increments the current interval for the next retry.
    ///
    /// Multiplies the current interval by the multiplier, capping at `maxInterval`.
    /// This is what creates the "exponential" growth in backoff times.
    private mutating func incrementCurrentInterval() {
        if currentInterval > maxInterval / multiplier {
            currentInterval = maxInterval
        } else {
            currentInterval *= multiplier
        }
    }
}
