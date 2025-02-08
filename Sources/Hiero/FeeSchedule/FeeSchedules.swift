// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// Contains the current and next `FeeSchedule`s.
///
/// See the [Hedera documentation]
///
/// [Hedera documentation]: https://docs.hedera.com/guides/docs/hedera-api/basic-types/currentandnextfeeschedule
public struct FeeSchedules {
    // missing_docs on memberwise init -> fine.
    // swiftlint:disable:next missing_docs
    public init(current: FeeSchedule? = nil, next: FeeSchedule? = nil) {
        self.current = current
        self.next = next
    }

    /// The current fee schedule.
    public var current: FeeSchedule?

    /// The next fee schedule.
    public var next: FeeSchedule?

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

extension FeeSchedules: TryProtobufCodable {
    internal typealias Protobuf = Proto_CurrentAndNextFeeSchedule

    internal init(protobuf proto: Protobuf) throws {
        self.init(
            current: proto.hasCurrentFeeSchedule ? try .fromProtobuf(proto.currentFeeSchedule) : nil,
            next: proto.hasNextFeeSchedule ? try .fromProtobuf(proto.nextFeeSchedule) : nil
        )
    }

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            if let current = current?.toProtobuf() {
                proto.currentFeeSchedule = current
            }

            if let next = next?.toProtobuf() {
                proto.nextFeeSchedule = next
            }
        }
    }
}
