// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// An explicit storage slot update.
public struct LambdaStorageSlot {
    /// The 32-byte storage slot key.
    public var key: Data

    /// The 32-byte storage slot value (leave empty to delete).
    public var value: Data

    public init(key: Data = Data(), value: Data = Data()) {
        self.key = key
        self.value = value
    }

    /// Set the storage slot key.
    @discardableResult
    public mutating func setKey(_ key: Data) -> Self {
        self.key = key
        return self
    }

    /// Set the storage slot value.
    @discardableResult
    public mutating func setValue(_ value: Data) -> Self {
        self.value = value
        return self
    }
}

extension LambdaStorageSlot: TryProtobufCodable {
    internal typealias Protobuf = Com_Hedera_Hapi_Node_Hooks_LambdaStorageSlot

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
