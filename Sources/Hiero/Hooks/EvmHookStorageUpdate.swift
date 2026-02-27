// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// Specifies a key/value pair in the storage of an EVM hook.
///
/// An update can be expressed in one of two ways:
/// - As an **explicit storage slot** (`storageSlot`), which directly sets a 256-bit key to a 256-bit value.
/// - As **Solidity mapping entries** (`mappingEntries`), which specify updates via a mapping's slot
///   and keys. This allows block stream consumers to understand which mapping entry was updated
///   without inverting a Keccak256 hash.
///
/// Exactly one of `storageSlot` or `mappingEntries` should be set.
public struct EvmHookStorageUpdate {
    /// An explicit storage slot update, if this update targets a raw slot.
    public var storageSlot: EvmHookStorageSlot?

    /// A Solidity mapping-based storage update, if this update targets mapping entries.
    public var mappingEntries: EvmHookMappingEntries?

    /// Create a new `EvmHookStorageUpdate`.
    ///
    /// - Parameters:
    ///   - storageSlot: An explicit storage slot update.
    ///   - mappingEntries: A mapping-based storage update.
    public init(storageSlot: EvmHookStorageSlot? = nil, mappingEntries: EvmHookMappingEntries? = nil) {
        self.storageSlot = storageSlot
        self.mappingEntries = mappingEntries
    }

    /// Sets an explicit storage slot update, clearing any mapping-based update.
    @discardableResult
    public mutating func setStorageSlot(_ storageSlot: EvmHookStorageSlot) -> Self {
        self.storageSlot = storageSlot
        self.mappingEntries = nil
        return self
    }

    /// Sets a Solidity mapping-based update, clearing any explicit storage slot update.
    @discardableResult
    public mutating func setMappingEntries(_ mappingEntries: EvmHookMappingEntries) -> Self {
        self.mappingEntries = mappingEntries
        self.storageSlot = nil
        return self
    }
}

extension EvmHookStorageUpdate: TryProtobufCodable {
    internal typealias Protobuf = Com_Hedera_Hapi_Node_Hooks_EvmHookStorageUpdate

    internal init(protobuf proto: Protobuf) throws {
        self.storageSlot = nil
        self.mappingEntries = nil

        if let which = proto.update {
            switch which {
            case .storageSlot(let slot):
                self.storageSlot = try EvmHookStorageSlot(protobuf: slot)
            case .mappingEntries(let entries):
                self.mappingEntries = try EvmHookMappingEntries(protobuf: entries)
            }
        }
    }

    internal func toProtobuf() -> Protobuf {
        var proto = Protobuf()

        if let slot = storageSlot {
            proto.update = .storageSlot(slot.toProtobuf())
        } else if let entries = mappingEntries {
            proto.update = .mappingEntries(entries.toProtobuf())
        } else {
            proto.update = nil
        }

        return proto
    }
}
