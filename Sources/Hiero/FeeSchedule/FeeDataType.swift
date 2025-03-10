// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// Possible `FeeData` subtypes.
public enum FeeDataType {
    /// The resource prices have no special scope.
    case `default`

    /// The resource prices are scoped to an operation on a fungible token.
    case tokenFungibleCommon

    /// The resource prices are scoped to an operation on a non-fungible token.
    case tokenNonFungibleUnique

    /// The resource prices are scoped to an operation on a fungible token with a custom fee schedule.
    case tokenFungibleCommonWithCustomFees

    /// The resource prices are scoped to an operation on a non-fungible token with a custom fee schedule.
    case tokenNonFungibleUniqueWithCustomFees

    /// The resource prices are scoped to a `ScheduleCreateTransaction`
    /// containing a `ContractExecuteTransaction`.
    case scheduleCreateContractCall

    /// The resource prices are scoped to a `TopicCreateTransaction`
    /// with custom fees.
    case topicCreateWithCustomFees
}

extension FeeDataType: TryProtobufCodable {
    internal typealias Protobuf = Proto_SubType

    internal init(protobuf proto: Proto_SubType) throws {
        switch proto {
        case .default: self = .default
        case .tokenFungibleCommon: self = .tokenFungibleCommon
        case .tokenNonFungibleUnique: self = .tokenNonFungibleUnique
        case .tokenFungibleCommonWithCustomFees: self = .tokenFungibleCommonWithCustomFees
        case .tokenNonFungibleUniqueWithCustomFees: self = .tokenNonFungibleUniqueWithCustomFees
        case .scheduleCreateContractCall: self = .scheduleCreateContractCall
        case .topicCreateWithCustomFees: self = .topicCreateWithCustomFees
        case .UNRECOGNIZED(let code):
            throw HError.fromProtobuf("unrecognized FeeDataType `\(code)`")
        }
    }

    internal func toProtobuf() -> Protobuf {
        switch self {
        case .default: return .default
        case .tokenFungibleCommon: return .tokenFungibleCommon
        case .tokenNonFungibleUnique: return .tokenNonFungibleUnique
        case .tokenFungibleCommonWithCustomFees: return .tokenFungibleCommonWithCustomFees
        case .tokenNonFungibleUniqueWithCustomFees: return .tokenNonFungibleUniqueWithCustomFees
        case .scheduleCreateContractCall: return .scheduleCreateContractCall
        case .topicCreateWithCustomFees: return .topicCreateWithCustomFees
        }
    }
}
