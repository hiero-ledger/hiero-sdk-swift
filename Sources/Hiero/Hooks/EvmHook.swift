// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// Definition of an EVM hook.
public struct EvmHook {
    /// The source of the EVM bytecode for the hook.
    public var contractId: ContractId?

    /// The initial storage updates for the EVM hook, if any.
    public var storageUpdates: [EvmHookStorageUpdate]

    public init(contractId: ContractId? = nil, storageUpdates: [EvmHookStorageUpdate] = []) {
        self.contractId = contractId
        self.storageUpdates = storageUpdates
    }

    /// Set the contract ID for this hook.
    @discardableResult
    public mutating func contractId(_ contractId: ContractId) -> Self {
        self.contractId = contractId
        return self
    }

    /// Add a storage update to this hook.
    @discardableResult
    public mutating func addStorageUpdate(_ storageUpdate: EvmHookStorageUpdate) -> Self {
        storageUpdates.append(storageUpdate)
        return self
    }

    /// Set the storage updates for this hook.
    @discardableResult
    public mutating func setStorageUpdates(_ storageUpdates: [EvmHookStorageUpdate]) -> Self {
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

extension EvmHook: TryProtobufCodable {
    internal typealias Protobuf = Com_Hedera_Hapi_Node_Hooks_EvmHook

    /// Construct from protobuf.
    internal init(protobuf proto: Protobuf) throws {
        if case .contractID(let id) = proto.spec.bytecodeSource {
            self.contractId = try ContractId.fromProtobuf(id)
        } else {
            self.contractId = nil
        }
        self.storageUpdates = try proto.storageUpdates.map { try EvmHookStorageUpdate(protobuf: $0) }
    }

    /// Convert to protobuf.
    internal func toProtobuf() -> Protobuf {
        var proto = Protobuf()
        if let contractId = contractId {
            var spec = Com_Hedera_Hapi_Node_Hooks_EvmHookSpec()
            spec.bytecodeSource = .contractID(contractId.toProtobuf())
            proto.spec = spec
        }
        proto.storageUpdates = storageUpdates.map { $0.toProtobuf() }
        return proto
    }
}
