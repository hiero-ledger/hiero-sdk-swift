// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs

/// A kind of freeze that can be executed by the Hedera network.
public enum FreezeType {
    /// An (invalid) default value for this enum, to ensure the client explicitly sets
    /// the intended type of freeze transaction.
    case unknown

    /// Freezes the network at the specified time. The start_time field must be provided and
    /// must reference a future time. Any values specified for the update_file and file_hash
    /// fields will be ignored. This transaction does not perform any network changes or
    /// upgrades and requires manual intervention to restart the network.
    case freezeOnly

    /// A non-freezing operation that initiates network wide preparation in advance of a
    /// scheduled freeze upgrade. The update_file and file_hash fields must be provided and
    /// valid. The start_time field may be omitted and any value present will be ignored.
    case prepareUpgrade

    /// Freezes the network at the specified time and performs the previously prepared
    /// automatic upgrade across the entire network.
    case freezeUpgrade

    /// Aborts a pending network freeze operation.
    case freezeAbort

    /// Performs an immediate upgrade on auxilary services and containers providing
    /// telemetry/metrics. Does not impact network operations.
    case telemetryUpgrade
}

extension FreezeType: TryProtobufCodable {
    internal typealias Protobuf = Proto_FreezeType

    internal init(protobuf proto: Protobuf) throws {
        switch proto {

        case .unknownFreezeType: self = .unknown
        case .freezeOnly: self = .freezeOnly
        case .prepareUpgrade: self = .prepareUpgrade
        case .freezeUpgrade: self = .freezeUpgrade
        case .freezeAbort: self = .freezeAbort
        case .telemetryUpgrade: self = .telemetryUpgrade
        case .UNRECOGNIZED(let value): throw HError.fromProtobuf("unrecognized FreezeType: `\(value)`")
        }
    }

    internal func toProtobuf() -> Protobuf {
        switch self {
        case .unknown: return .unknownFreezeType
        case .freezeOnly: return .freezeOnly
        case .prepareUpgrade: return .prepareUpgrade
        case .freezeUpgrade: return .freezeUpgrade
        case .freezeAbort: return .freezeAbort
        case .telemetryUpgrade: return .telemetryUpgrade
        }
    }
}
