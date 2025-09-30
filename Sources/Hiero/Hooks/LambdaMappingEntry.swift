// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// An implicit storage slot specified as a Solidity mapping entry.
public struct LambdaMappingEntry {
    /// The slot corresponding to the Solidity mapping.
    public var mappingSlot: Data

    /// The 32-byte key of the mapping entry.
    public var key: Data

    /// The 32-byte value of the mapping entry (leave empty to delete).
    public var value: Data

    public init(mappingSlot: Data = Data(), key: Data = Data(), value: Data = Data()) {
        self.mappingSlot = mappingSlot
        self.key = key
        self.value = value
    }

    /// Set the Solidity mapping slot.
    @discardableResult
    public mutating func setMappingSlot(_ mappingSlot: Data) -> Self {
        self.mappingSlot = mappingSlot
        return self
    }

    /// Set the key for the mapping entry.
    @discardableResult
    public mutating func setKey(_ key: Data) -> Self {
        self.key = key
        return self
    }

    /// Set the value for the mapping entry.
    @discardableResult
    public mutating func setValue(_ value: Data) -> Self {
        self.value = value
        return self
    }
}

extension LambdaMappingEntry: TryProtobufCodable {
    internal typealias Protobuf = Com_Hedera_Hapi_Node_Hooks_LambdaMappingEntry

    /// Construct from protobuf.
    internal init(protobuf proto: Protobuf) throws {
        self.mappingSlot = proto.mappingSlot
        self.key = proto.key
        self.value = proto.value
    }

    /// Convert to protobuf.
    internal func toProtobuf() -> Protobuf {
        var proto = Protobuf()
        proto.mappingSlot = mappingSlot
        proto.key = key
        proto.value = value
        return proto
    }
}
