// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SwiftProtobuf

/// Possible token supply types.
/// Can be used to restrict supply to a set maximum.
///
/// Defaults to ``infinite``.
public enum TokenSupplyType {
    /// Indicates the token has a maximum supply of `UInt64.max`.
    case infinite
    /// Indicates the token has a configurable maximum supply, provided on token creation.
    case finite
}

extension TokenSupplyType: TryProtobufCodable {
    internal typealias Protobuf = Proto_TokenSupplyType

    internal init(protobuf proto: HieroProtobufs.Proto_TokenSupplyType) throws {
        switch proto {
        case .infinite:
            self = .infinite
        case .finite:
            self = .finite
        case .UNRECOGNIZED(let value):
            throw HError.fromProtobuf("unrecognized TokenSupplyType: `\(value)`")
        }
    }

    internal func toProtobuf() -> HieroProtobufs.Proto_TokenSupplyType {
        switch self {
        case .infinite:
            return .infinite
        case .finite:
            return .finite
        }
    }
}
