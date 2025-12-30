// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// The extra fee charged for the transaction.
///
/// All properties are immutable (`@immutable` in the specification).
public struct FeeExtra {
    /// The unique name of this extra fee as defined in the fee schedule.
    /// Immutable after initialization.
    public let name: String

    /// The count of this "extra" that is included for free.
    /// Immutable after initialization.
    public let included: UInt32

    /// The actual count of items received.
    /// Immutable after initialization.
    public let count: UInt32

    /// The charged count of items as calculated by max(0, count - included).
    /// Immutable after initialization.
    public let charged: UInt32

    /// The fee price per unit in tinycents.
    /// Immutable after initialization.
    public let feePerUnit: UInt64

    /// The subtotal in tinycents for this extra fee. Calculated by multiplying the
    /// charged count by the feePerUnit.
    /// Immutable after initialization.
    public let subtotal: UInt64

    internal init(
        name: String,
        included: UInt32,
        count: UInt32,
        charged: UInt32,
        feePerUnit: UInt64,
        subtotal: UInt64
    ) {
        self.name = name
        self.included = included
        self.count = count
        self.charged = charged
        self.feePerUnit = feePerUnit
        self.subtotal = subtotal
    }
}

extension FeeExtra: TryProtobufCodable {
    internal typealias Protobuf = Com_Hedera_Mirror_Api_Proto_FeeExtra

    internal init(protobuf proto: Protobuf) throws {
        self.init(
            name: proto.name,
            included: UInt32(proto.included),
            count: UInt32(proto.count),
            charged: UInt32(proto.charged),
            feePerUnit: proto.feePerUnit,
            subtotal: proto.subtotal
        )
    }

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.name = name
            proto.included = UInt32(included)
            proto.count = UInt32(count)
            proto.charged = UInt32(charged)
            proto.feePerUnit = feePerUnit
            proto.subtotal = subtotal
        }
    }
}

// MARK: - JSON Parsing

extension FeeExtra {
    /// Parse a `FeeExtra` from a JSON dictionary.
    internal static func fromJson(_ json: [String: Any]) throws -> FeeExtra {
        let name = json["name"] as? String ?? ""
        let included = (json["included"] as? NSNumber)?.uint32Value ?? 0
        let count = (json["count"] as? NSNumber)?.uint32Value ?? 0
        let charged = (json["charged"] as? NSNumber)?.uint32Value ?? 0
        let feePerUnit = (json["fee_per_unit"] as? NSNumber)?.uint64Value ?? 0
        let subtotal = (json["subtotal"] as? NSNumber)?.uint64Value ?? 0

        return FeeExtra(
            name: name,
            included: included,
            count: count,
            charged: charged,
            feePerUnit: feePerUnit,
            subtotal: subtotal
        )
    }
}

