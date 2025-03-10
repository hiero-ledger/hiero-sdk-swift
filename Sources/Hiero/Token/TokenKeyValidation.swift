// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

public enum TokenKeyValidation {
    /// Currently the default behaviour. It will perform all token key validations.
    case fullValidation
    /// Perform no validations at all for all passed token keys.
    case noValidation
    /// The passed token key is not recognized.
    case unrecognized(Int)
}

extension TokenKeyValidation: TryFromProtobuf {
    internal typealias Protobuf = Proto_TokenKeyValidation

    internal init(protobuf proto: Protobuf) throws {
        switch proto {
        case .fullValidation: self = .fullValidation
        case .noValidation: self = .noValidation
        case .UNRECOGNIZED(let value): self = .unrecognized(value)
        }
    }

    func toProtobuf() -> Protobuf {
        switch self {
        case .fullValidation:
            return .fullValidation
        case .noValidation:
            return .noValidation
        case .unrecognized(let value):
            return .UNRECOGNIZED(value)
        }
    }
}
