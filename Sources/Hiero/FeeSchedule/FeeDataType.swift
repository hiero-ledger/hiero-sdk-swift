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

    /// The resource cost for the transaction type includes a ConsensusSubmitMessage
    /// for a topic with custom fees.
    case submitMessageWithCustomFees

    /// The resource cost for the transaction type that includes a CryptoTransfer with hook invocations
    case cryptoTransferWithHooks
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
        case .submitMessageWithCustomFees: self = .submitMessageWithCustomFees
        case .cryptoTransferWithHooks: self = .cryptoTransferWithHooks
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
        case .submitMessageWithCustomFees: return .submitMessageWithCustomFees
        case .cryptoTransferWithHooks: return .cryptoTransferWithHooks
        }
    }
}
