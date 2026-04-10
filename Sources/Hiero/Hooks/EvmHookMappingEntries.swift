// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// Specifies storage slot updates via indirection into a Solidity mapping.
///
/// Concretely, if the Solidity mapping is itself at slot `mappingSlot`, then the
/// storage slot for a given `key` in the mapping is defined by:
///
///     key_storage_slot = keccak256(abi.encodePacked(mappingSlot, key))
///
/// This lets a metaprotocol be specified in terms of changes to a Solidity mapping's entries.
/// If only raw slots could be updated, a block stream consumer would have to invert the
/// Keccak256 hash to determine which mapping entry was updated, which is computationally
/// infeasible.
public struct EvmHookMappingEntries {
    /// The slot that corresponds to the Solidity mapping itself.
    public var mappingSlot: Data

    /// The entries in the mapping at the given slot.
    public var entries: [EvmHookMappingEntry]

    /// Create a new `EvmHookMappingEntries`.
    ///
    /// - Parameters:
    ///   - mappingSlot: The slot corresponding to the Solidity mapping.
    ///   - entries: The mapping entries to update.
    public init(mappingSlot: Data = Data(), entries: [EvmHookMappingEntry] = []) {
        self.mappingSlot = mappingSlot
        self.entries = entries
    }

    /// Sets the slot that corresponds to the Solidity mapping.
    @discardableResult
    public mutating func mappingSlot(_ mappingSlot: Data) -> Self {
        self.mappingSlot = mappingSlot
        return self
    }

    /// Adds a single mapping entry to update.
    @discardableResult
    public mutating func addEntry(_ entry: EvmHookMappingEntry) -> Self {
        self.entries.append(entry)
        return self
    }

    /// Sets all mapping entries to update.
    @discardableResult
    public mutating func setEntries(_ entries: [EvmHookMappingEntry]) -> Self {
        self.entries = entries
        return self
    }

    /// Removes all mapping entries.
    @discardableResult
    public mutating func clearEntries() -> Self {
        self.entries.removeAll()
        return self
    }
}

extension EvmHookMappingEntries: TryProtobufCodable {
    internal typealias Protobuf = Com_Hedera_Hapi_Node_Hooks_EvmHookMappingEntries

    /// Construct from protobuf.
    internal init(protobuf proto: Protobuf) throws {
        self.mappingSlot = proto.mappingSlot
        self.entries = try proto.entries.map { try EvmHookMappingEntry(protobuf: $0) }
    }

    /// Convert to protobuf.
    internal func toProtobuf() -> Protobuf {
        var proto = Protobuf()
        proto.mappingSlot = mappingSlot
        proto.entries = entries.map { $0.toProtobuf() }
        return proto
    }
}
