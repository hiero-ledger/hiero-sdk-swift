// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// Definition of a lambda EVM hook.
public struct LambdaEvmHook {
    /// Shared EVM hook spec (e.g., contract housing the hook bytecode).
    public var spec: EvmHookSpec

    /// The initial storage updates for the lambda, if any.
    public var storageUpdates: [LambdaStorageUpdate]

    public init(spec: EvmHookSpec = .init(), storageUpdates: [LambdaStorageUpdate] = []) {
        self.spec = spec
        self.storageUpdates = storageUpdates
    }

    /// Add a storage update to this hook.
    @discardableResult
    public mutating func addStorageUpdate(_ storageUpdate: LambdaStorageUpdate) -> Self {
        storageUpdates.append(storageUpdate)
        return self
    }

    /// Set the storage updates for this hook.
    @discardableResult
    public mutating func setStorageUpdates(_ storageUpdates: [LambdaStorageUpdate]) -> Self {
        self.storageUpdates = storageUpdates
        return self
    }

    /// Clear the storage updates for this hook.
    @discardableResult
    public mutating func clearStorageUpdates() -> Self {
        storageUpdates.removeAll()
        return self
    }
}

extension LambdaEvmHook: TryProtobufCodable {
    internal typealias Protobuf = Com_Hedera_Hapi_Node_Hooks_LambdaEvmHook

    /// Construct from protobuf.
    internal init(protobuf proto: Protobuf) throws {
        // Assuming the generated message has `spec` and `storageUpdates` fields.
        self.spec = try EvmHookSpec(protobuf: proto.spec)
        self.storageUpdates = try proto.storageUpdates.map { try LambdaStorageUpdate(protobuf: $0) }
    }

    /// Convert to protobuf.
    internal func toProtobuf() -> Protobuf {
        var proto = Protobuf()
        proto.spec = spec.toProtobuf()
        proto.storageUpdates = storageUpdates.map { $0.toProtobuf() }
        return proto
    }
}
