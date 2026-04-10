// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// Definition of an EVM hook, including the source of its bytecode and optional initial storage.
///
/// An EVM hook is programmed by writing a contract in a language like Solidity that compiles
/// to EVM bytecode. The hook's bytecode is sourced from an existing contract on the network
/// identified by `contractId`. When the hook executes, its bytecode always runs at the special
/// address `0x16d` and has the Hiero privileges of its owning entity.
public struct EvmHook {
    /// The ID of the contract whose bytecode implements this hook's logic.
    public var contractId: ContractId?

    /// Initial storage slot updates to apply when the hook is created.
    ///
    /// Each update can be either an explicit storage slot or a Solidity mapping entry.
    public var storageUpdates: [EvmHookStorageUpdate]

    /// Create a new `EvmHook`.
    ///
    /// - Parameters:
    ///   - contractId: The contract whose bytecode implements the hook.
    ///   - storageUpdates: Initial storage updates to apply at hook creation.
    public init(contractId: ContractId? = nil, storageUpdates: [EvmHookStorageUpdate] = []) {
        self.contractId = contractId
        self.storageUpdates = storageUpdates
    }

    /// Sets the contract whose bytecode implements this hook's logic.
    @discardableResult
    public mutating func contractId(_ contractId: ContractId) -> Self {
        self.contractId = contractId
        return self
    }

    /// Adds a storage update to be applied when the hook is created.
    @discardableResult
    public mutating func addStorageUpdate(_ storageUpdate: EvmHookStorageUpdate) -> Self {
        storageUpdates.append(storageUpdate)
        return self
    }

    /// Sets all storage updates to be applied when the hook is created.
    @discardableResult
    public mutating func setStorageUpdates(_ storageUpdates: [EvmHookStorageUpdate]) -> Self {
        self.storageUpdates = storageUpdates
        return self
    }

    /// Removes all storage updates.
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
