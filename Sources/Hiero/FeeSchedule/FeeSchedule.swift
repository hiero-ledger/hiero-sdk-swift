// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// The fee schedules for hedera functionality and the time at which this fee schedule will expire.
///
/// See the [Hedera documentation].
///
/// [Hedera documentation]: https://docs.hedera.com/guides/docs/hedera-api/basic-types/feeschedule
public struct FeeSchedule {
    // missing_docs on memberwise init -> fine.
    // swiftlint:disable:next missing_docs
    public init(transactionFeeSchedules: [TransactionFeeSchedule] = [], expirationTime: Timestamp) {
        self.transactionFeeSchedules = transactionFeeSchedules
        self.expirationTime = expirationTime
    }

    /// The fee schedules per specific piece of functionality.
    public var transactionFeeSchedules: [TransactionFeeSchedule]

    /// The time this fee schedule will expire at.
    public var expirationTime: Timestamp

    /// Decode `Self` from protobuf-encoded `bytes`.
    ///
    /// - Throws: ``HError/ErrorKind/fromProtobuf`` if:
    ///           decoding the bytes fails to produce a valid protobuf, or
    ///            decoding the protobuf fails.
    public static func fromBytes(_ bytes: Data) throws -> Self {
        try Self(protobufBytes: bytes)
    }

    /// Convert `self` to protobuf encoded data.
    public func toBytes() -> Data {
        toProtobufBytes()
    }
}

extension FeeSchedule: TryProtobufCodable {
    internal typealias Protobuf = Proto_FeeSchedule

    internal init(protobuf proto: Protobuf) throws {
        self.init(
            transactionFeeSchedules: try .fromProtobuf(proto.transactionFeeSchedule),
            expirationTime: .init(seconds: UInt64(proto.expiryTime.seconds), subSecondNanos: 0)
        )
    }

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.transactionFeeSchedule = transactionFeeSchedules.toProtobuf()
            proto.expiryTime = .with { $0.seconds = Int64(expirationTime.seconds) }
        }
    }
}
