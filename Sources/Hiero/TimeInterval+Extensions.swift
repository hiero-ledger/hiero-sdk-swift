// SPDX-License-Identifier: Apache-2.0

import Foundation

// MARK: - TimeInterval Extensions

extension TimeInterval {
    /// Converts seconds to nanoseconds for Task.sleep() and timestamp calculations.
    ///
    /// This is useful when working with Swift's `Task.sleep(nanoseconds:)` or
    /// timestamp arithmetic that requires nanosecond precision.
    ///
    /// ## Example
    /// ```swift
    /// let delay: TimeInterval = 2.5  // 2.5 seconds
    /// try await Task.sleep(nanoseconds: delay.nanoseconds)  // Sleep for 2,500,000,000 nanoseconds
    /// ```
    ///
    /// - Returns: The time interval converted to nanoseconds as a UInt64
    internal var nanoseconds: UInt64 {
        UInt64(self * 1_000_000_000)
    }
}
