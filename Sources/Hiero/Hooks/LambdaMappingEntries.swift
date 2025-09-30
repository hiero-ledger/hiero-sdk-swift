// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// Specifies storage slot updates via indirection into a Solidity mapping.
///
/// Concretely, if the Solidity mapping is itself at slot `mapping_slot`, then the
/// storage slot for key `key` in the mapping is defined by:
/// `key_storage_slot = keccak256(abi.encodePacked(mapping_slot, key))`.
///
/// This message lets a metaprotocol be specified in terms of changes to a Solidity
/// mapping's entries. If only raw slots could be updated, then a block stream consumer
/// following the metaprotocol would have to invert the Keccak256 hash to determine
/// which mapping entry was being updated, which is not possible.
public struct LambdaMappingEntries {
    /// The slot corresponding to the Solidity mapping.
    public var mappingSlot: Data

    /// The mapping entries for this mapping slot.
    public var entries: [LambdaMappingEntry]

    public init(mappingSlot: Data = Data(), entries: [LambdaMappingEntry] = []) {
        self.mappingSlot = mappingSlot
        self.entries = entries
    }

    /// Set the Solidity mapping slot.
    @discardableResult
    public mutating func mappingSlot(_ mappingSlot: Data) -> Self {
        self.mappingSlot = mappingSlot
        return self
    }

    /// Add a mapping entry.
    @discardableResult
    public mutating func addEntry(_ entry: LambdaMappingEntry) -> Self {
        self.entries.append(entry)
        return self
    }

    /// Set all mapping entries.
    @discardableResult
    public mutating func setEntries(_ entries: [LambdaMappingEntry]) -> Self {
        self.entries = entries
        return self
    }

    /// Clear the mapping entries.
    @discardableResult
    public mutating func clearEntries() -> Self {
        self.entries.removeAll()
        return self
    }
}

extension LambdaMappingEntries: TryProtobufCodable {
    internal typealias Protobuf = Com_Hedera_Hapi_Node_Hooks_LambdaMappingEntries

    /// Construct from protobuf.
    internal init(protobuf proto: Protobuf) throws {
        self.mappingSlot = proto.mappingSlot
        self.entries = try proto.entries.map { try LambdaMappingEntry(protobuf: $0) }
    }

    /// Convert to protobuf.
    internal func toProtobuf() -> Protobuf {
        var proto = Protobuf()
        proto.mappingSlot = mappingSlot
        proto.entries = entries.map { $0.toProtobuf() }
        return proto
    }
}
