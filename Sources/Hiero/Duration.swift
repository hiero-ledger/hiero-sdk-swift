import Foundation
import HieroProtobufs

/// A time duration used throughout the SDK for transaction validity periods,
/// auto-renew periods, and other time-based configurations.
///
/// `Duration` provides a type-safe way to express time intervals in seconds,
/// with convenient factory methods for common time units.
///
/// ## Example Usage
/// ```swift
/// // Create a duration of 30 days
/// let autoRenewPeriod = Duration.days(30)
///
/// // Create a duration of 2 hours
/// let validityPeriod = Duration.hours(2)
///
/// // Create a duration of 120 seconds
/// let timeout = Duration.seconds(120)
/// ```
public struct Duration: Equatable, Sendable {
    /// The duration expressed in seconds.
    public let seconds: UInt64

    /// Creates a new duration with the specified number of seconds.
    ///
    /// - Parameter seconds: The number of seconds for this duration.
    public init(seconds: UInt64) {
        self.seconds = seconds
    }

    /// Creates a duration representing the specified number of days.
    ///
    /// - Parameter days: The number of days.
    /// - Returns: A `Duration` equivalent to the specified number of days.
    public static func days(_ days: UInt64) -> Self {
        .hours(days * 24)
    }

    /// Creates a duration representing the specified number of hours.
    ///
    /// - Parameter hours: The number of hours.
    /// - Returns: A `Duration` equivalent to the specified number of hours.
    public static func hours(_ hours: UInt64) -> Self {
        .minutes(hours * 60)
    }

    /// Creates a duration representing the specified number of minutes.
    ///
    /// - Parameter minutes: The number of minutes.
    /// - Returns: A `Duration` equivalent to the specified number of minutes.
    public static func minutes(_ minutes: UInt64) -> Self {
        .seconds(minutes * 60)
    }

    /// Creates a duration representing the specified number of seconds.
    ///
    /// - Parameter seconds: The number of seconds.
    /// - Returns: A `Duration` with the specified seconds value.
    public static func seconds(_ seconds: UInt64) -> Self {
        Self(seconds: seconds)
    }
}

extension Duration: ProtobufCodable {
    internal typealias Protobuf = Proto_Duration

    internal init(protobuf proto: Protobuf) {
        seconds = UInt64(bitPattern: proto.seconds)
    }

    internal func toProtobuf() -> Protobuf {
        .with { proto in proto.seconds = Int64(truncatingIfNeeded: seconds) }
    }
}
