// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// The network fee component which covers the cost of gossip, consensus,
/// signature verifications, fee payment, and storage.
///
/// All properties are immutable (`@immutable` in the specification).
public struct NetworkFee {
    /// Multiplied by the node fee to determine the total network fee.
    /// Immutable after initialization.
    public let multiplier: UInt32

    /// The subtotal in tinycents for the network fee component which is calculated by
    /// multiplying the node subtotal by the network multiplier.
    /// Immutable after initialization.
    public let subtotal: UInt64

    internal init(multiplier: UInt32, subtotal: UInt64) {
        self.multiplier = multiplier
        self.subtotal = subtotal
    }
}

extension NetworkFee: TryProtobufCodable {
    internal typealias Protobuf = Com_Hedera_Mirror_Api_Proto_NetworkFee

    internal init(protobuf proto: Protobuf) throws {
        self.init(
            multiplier: UInt32(proto.multiplier),
            subtotal: proto.subtotal
        )
    }

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.multiplier = UInt32(multiplier)
            proto.subtotal = subtotal
        }
    }
}

// MARK: - JSON Parsing

extension NetworkFee {
    /// Parse a `NetworkFee` from a JSON dictionary.
    internal static func fromJson(_ json: [String: Any]) throws -> NetworkFee {
        let multiplier = (json["multiplier"] as? NSNumber)?.uint32Value ?? 0
        let subtotal = (json["subtotal"] as? NSNumber)?.uint64Value ?? 0

        return NetworkFee(multiplier: multiplier, subtotal: subtotal)
    }
}

