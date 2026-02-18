// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// An implicit storage slot specified as a Solidity mapping entry.
public struct LambdaMappingEntry {
    /// The 32-byte key of the mapping entry.
    public var key: Data?

    /// The slot corresponding to the Solidity mapping.
    public var preimage: Data?

    /// The 32-byte value of the mapping entry (leave empty to delete).
    public var value: Data

    public init(key: Data = Data(), preimage: Data = Data(), value: Data = Data()) {
        self.key = key
        self.preimage = preimage
        self.value = value
    }

    /// Set the key for the mapping entry.
    @discardableResult
    public mutating func key(_ key: Data) -> Self {
        self.key = key
        self.preimage = nil  // Reset preimage when setting key
        return self
    }

    /// Set the Solidity preimage.
    @discardableResult
    public mutating func preimage(_ preimage: Data) -> Self {
        self.preimage = preimage
        self.key = nil  // Reset key when setting preimage
        return self
    }

    /// Set the value for the mapping entry.
    @discardableResult
    public mutating func value(_ value: Data) -> Self {
        self.value = value
        return self
    }
}

extension LambdaMappingEntry: TryProtobufCodable {
    internal typealias Protobuf = Com_Hedera_Hapi_Node_Hooks_LambdaMappingEntry

    /// Construct from protobuf.
    internal init(protobuf proto: Protobuf) throws {
        self.key = proto.key
        self.preimage = proto.preimage
        self.value = proto.value
    }

    /// Convert to protobuf.
    internal func toProtobuf() -> Protobuf {
        var proto = Protobuf()

        if let key = key {
            proto.key = key
        }

        if let preimage = preimage {
            proto.preimage = preimage
        }

        proto.value = value
        return proto
    }
}
