import Foundation
import HieroProtobufs

private let nanosPerSecond: UInt64 = 1_000_000_000

private let timeZoneUTC: TimeZone = TimeZone(abbreviation: "UTC")!

private let unixEpoch: Date = Calendar.current.date(from: DateComponents(timeZone: timeZoneUTC, year: 1970))!

/// UNIX timestamp with nanosecond precision
public struct Timestamp: Sendable, Equatable, Hashable, CustomStringConvertible, Comparable {
    public static func < (lhs: Timestamp, rhs: Timestamp) -> Bool {
        lhs.seconds < rhs.seconds || (lhs.seconds == rhs.seconds && lhs.subSecondNanos < rhs.subSecondNanos)
    }

    public let seconds: UInt64
    public let subSecondNanos: UInt32

    public init(seconds: UInt64, subSecondNanos: UInt32) {
        self.seconds = seconds + UInt64(subSecondNanos) / nanosPerSecond
        self.subSecondNanos = subSecondNanos % UInt32(nanosPerSecond)
    }

    public init(fromUnixTimestampNanos nanos: UInt64) {
        self.seconds = nanos / nanosPerSecond
        self.subSecondNanos = UInt32(nanos % nanosPerSecond)
    }

    internal func adding(nanos: UInt64) -> Self {
        Self(fromUnixTimestampNanos: unixTimestampNanos + nanos)
    }

    internal func subtracting(nanos: UInt64) -> Self {
        Self(fromUnixTimestampNanos: unixTimestampNanos - nanos)
    }

    public static var now: Self {
        Self(from: Date())
    }

    /// Convert from a `Date` to a `Timestamp`
    ///
    /// `Date` is stored as `Double` seconds, so, it may not have full precision.
    public init(from date: Date) {
        let components = Calendar.current.dateComponents([.second, .nanosecond], from: unixEpoch, to: date)

        seconds = UInt64(components.second!)
        subSecondNanos = UInt32(components.nanosecond!)
    }

    // todo: what do on overflow?
    public var unixTimestampNanos: UInt64 {
        seconds * nanosPerSecond + UInt64(subSecondNanos)
    }

    /// Convert from a `Timestamp` to a `Date`
    ///
    /// `Date` is stored as `Double` seconds, so, it may not have full precision.
    public func toDate() -> Date {
        let components = DateComponents(timeZone: timeZoneUTC, second: Int(seconds), nanosecond: Int(subSecondNanos))

        return Calendar.current.date(byAdding: components, to: unixEpoch)!
    }

    public var description: String {
        String(describing: seconds) + String(format: "%09d", subSecondNanos)
    }

    public static func + (lhs: Self, rhs: Duration) -> Self {
        Self(seconds: lhs.seconds + rhs.seconds, subSecondNanos: lhs.subSecondNanos)
    }

    public static func - (lhs: Self, rhs: Duration) -> Self {
        Self(seconds: lhs.seconds - rhs.seconds, subSecondNanos: lhs.subSecondNanos)
    }

    internal static func - (lhs: Self, rhs: Self) -> Duration {
        Duration(seconds: (lhs.unixTimestampNanos - rhs.unixTimestampNanos) / nanosPerSecond)
    }
}

extension Timestamp: ProtobufCodable {
    internal typealias Protobuf = Proto_Timestamp

    internal init(protobuf proto: Protobuf) {
        self.init(
            seconds: UInt64(bitPattern: proto.seconds),
            subSecondNanos: UInt32(bitPattern: proto.nanos)
        )
    }

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.seconds = Int64(truncatingIfNeeded: seconds)
            proto.nanos = Int32(truncatingIfNeeded: subSecondNanos)
        }
    }
}
