// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs

/// The fee estimate for a component. Includes the base fee and any extras.
///
/// All properties are immutable (`@immutable` in the specification).
public struct FeeEstimate {
    /// The base fee price, in tinycents.
    /// Immutable after initialization.
    public let base: UInt64

    /// The extra fees that apply for this fee component.
    /// Immutable after initialization. The array and its contents cannot be modified.
    public let extras: [FeeExtra]

    internal init(base: UInt64, extras: [FeeExtra]) {
        self.base = base
        self.extras = extras
    }
}

extension FeeEstimate: TryProtobufCodable {
    internal typealias Protobuf = Com_Hedera_Mirror_Api_Proto_FeeEstimate

    internal init(protobuf proto: Protobuf) throws {
        self.init(
            base: proto.base,
            extras: try .fromProtobuf(proto.extras)
        )
    }

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.base = base
            proto.extras = extras.toProtobuf()
        }
    }
}

