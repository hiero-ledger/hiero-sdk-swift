// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// Specifies a key/value pair in the storage of a lambda, either by the explicit storage slot contents;
/// or by a combination of a Solidity mapping's slot key and the key into that mapping.
public struct LambdaStorageUpdate {
    /// An explicit storage slot update.
    public var storageSlot: LambdaStorageSlot?

    /// An implicit storage slot update specified as Solidity mapping entries.
    public var mappingEntries: LambdaMappingEntries?

    public init(storageSlot: LambdaStorageSlot? = nil, mappingEntries: LambdaMappingEntries? = nil) {
        self.storageSlot = storageSlot
        self.mappingEntries = mappingEntries
    }

    /// Set an update for an explicit storage slot. Resets any mapping-based update.
    @discardableResult
    public mutating func setStorageSlot(_ storageSlot: LambdaStorageSlot) -> Self {
        self.storageSlot = storageSlot
        self.mappingEntries = nil
        return self
    }

    /// Set an update for Solidity-mapped entries. Resets any explicit-slot update.
    @discardableResult
    public mutating func setMappingEntries(_ mappingEntries: LambdaMappingEntries) -> Self {
        self.mappingEntries = mappingEntries
        self.storageSlot = nil
        return self
    }
}

extension LambdaStorageUpdate: TryProtobufCodable {
    internal typealias Protobuf = Com_Hedera_Hapi_Node_Hooks_LambdaStorageUpdate

    internal init(protobuf proto: Protobuf) throws {
        // Default to nils
        self.storageSlot = nil
        self.mappingEntries = nil

        // Handle the `oneof` for which update is present.
        if let which = proto.update {
            switch which {
            case .storageSlot(let slot):
                self.storageSlot = try LambdaStorageSlot(protobuf: slot)
            case .mappingEntries(let entries):
                self.mappingEntries = try LambdaMappingEntries(protobuf: entries)
            }
        }
    }

    internal func toProtobuf() -> Protobuf {
        var proto = Protobuf()

        // Set exactly one branch of the oneof (or leave nil if neither is set).
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
