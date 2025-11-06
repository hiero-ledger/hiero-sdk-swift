// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs

/// The mode of fee estimation.
public enum FeeEstimateMode {
    /// Default: uses latest known state
    case state
    /// Ignores state-dependent factors
    case intrinsic
}

extension FeeEstimateMode: TryProtobufCodable {
    internal typealias Protobuf = Com_Hedera_Mirror_Api_Proto_EstimateMode

    internal init(protobuf proto: Protobuf) throws {
        switch proto {
        case .state:
            self = .state
        case .intrinsic:
            self = .intrinsic
        case .UNRECOGNIZED(let value):
            throw HError.fromProtobuf("unrecognized FeeEstimateMode: \(value)")
        }
    }

    internal func toProtobuf() -> Protobuf {
        switch self {
        case .state:
            return .state
        case .intrinsic:
            return .intrinsic
        }
    }
}

