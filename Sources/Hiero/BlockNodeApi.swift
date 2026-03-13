// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs

/// An enumeration of well-known block node endpoint APIs.
public enum BlockNodeApi {
    case other
    case status
    case publish
    case subscribeStream
    case stateProof
}

extension BlockNodeApi: TryProtobufCodable {
    internal typealias Protobuf =
        Com_Hedera_Hapi_Node_Addressbook_RegisteredServiceEndpoint.BlockNodeEndpoint.BlockNodeApi

    internal init(protobuf proto: Protobuf) throws {
        switch proto {
        case .other: self = .other
        case .status: self = .status
        case .publish: self = .publish
        case .subscribeStream: self = .subscribeStream
        case .stateProof: self = .stateProof
        case .UNRECOGNIZED(let value):
            throw HError.fromProtobuf("unrecognized BlockNodeApi value \(value)")
        }
    }

    internal func toProtobuf() -> Protobuf {
        switch self {
        case .other: return .other
        case .status: return .status
        case .publish: return .publish
        case .subscribeStream: return .subscribeStream
        case .stateProof: return .stateProof
        }
    }
}
