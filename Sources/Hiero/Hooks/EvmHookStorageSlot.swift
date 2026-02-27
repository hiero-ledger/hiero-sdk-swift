// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// An explicit EVM storage slot, represented as a 256-bit key/value pair.
///
/// For each EVM hook, its storage is a mapping of 256-bit keys (words) to 256-bit values.
/// Setting the value to empty or all zeros removes the slot.
public struct EvmHookStorageSlot {
    /// The 32-byte storage slot key; leading zeros may be omitted.
    public var key: Data

    /// The 32-byte storage slot value; leading zeros may be omitted.
    ///
    /// Setting this to empty or all zeros removes the slot.
    public var value: Data

    /// Create a new `EvmHookStorageSlot`.
    ///
    /// - Parameters:
    ///   - key: The 32-byte storage slot key.
    ///   - value: The 32-byte storage slot value (empty to remove the slot).
    public init(key: Data = Data(), value: Data = Data()) {
        self.key = key
        self.value = value
    }

    /// Sets the 32-byte storage slot key.
    @discardableResult
    public mutating func key(_ key: Data) -> Self {
        self.key = key
        return self
    }

    /// Sets the 32-byte storage slot value.
    ///
    /// Setting this to empty or all zeros removes the slot.
    @discardableResult
    public mutating func value(_ value: Data) -> Self {
        self.value = value
        return self
    }
}

extension EvmHookStorageSlot: TryProtobufCodable {
    internal typealias Protobuf = Com_Hedera_Hapi_Node_Hooks_EvmHookStorageSlot

    /// Construct from protobuf.
    internal init(protobuf proto: Protobuf) throws {
        self.key = proto.key
        self.value = proto.value
    }

    /// Convert to protobuf.
    internal func toProtobuf() -> Protobuf {
        var proto = Protobuf()
        proto.key = key
        proto.value = value
        return proto
    }
}
