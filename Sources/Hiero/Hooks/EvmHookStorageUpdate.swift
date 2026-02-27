// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// Specifies a key/value pair in the storage of an EVM hook, either by the explicit storage slot contents;
/// or by a combination of a Solidity mapping's slot key and the key into that mapping.
public struct EvmHookStorageUpdate {
    /// An explicit storage slot update.
    public var storageSlot: EvmHookStorageSlot?

    /// An implicit storage slot update specified as Solidity mapping entries.
    public var mappingEntries: EvmHookMappingEntries?

    public init(storageSlot: EvmHookStorageSlot? = nil, mappingEntries: EvmHookMappingEntries? = nil) {
        self.storageSlot = storageSlot
        self.mappingEntries = mappingEntries
    }

    /// Set an update for an explicit storage slot. Resets any mapping-based update.
    @discardableResult
    public mutating func setStorageSlot(_ storageSlot: EvmHookStorageSlot) -> Self {
        self.storageSlot = storageSlot
        self.mappingEntries = nil
        return self
    }

    /// Set an update for Solidity-mapped entries. Resets any explicit-slot update.
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
