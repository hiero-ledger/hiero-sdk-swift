// SPDX-License-Identifier: Apache-2.0

import Foundation
import GRPC
import HieroProtobufs

/// Adds or removes key/value pairs in the storage of an EVM hook.
///
/// Unlike smart contracts, which require a `ContractCall` to update storage, EVM hooks
/// support direct storage manipulation via this transaction. This permits fast, direct
/// adjustments to a hook's behavior with less overhead than a typical
/// `ConsensusSubmitMessage` and far less than a `ContractCall`.
///
/// Either the hook owner's key or the hook's admin key (set during creation) must sign
/// this transaction.
public final class HookStoreTransaction: Transaction {
    internal override var defaultMaxTransactionFee: Hbar {
        20
    }

    /// Create a new `HookStoreTransaction` ready for configuration.
    public override init() {
        super.init()
    }

    /// The fully-qualified ID of the EVM hook whose storage is being updated.
    public var hookId: HookId? {
        willSet { ensureNotFrozen() }
    }

    /// The storage updates to apply to the hook.
    ///
    /// Each update can target either an explicit storage slot or a Solidity mapping entry.
    public var storageUpdates: [EvmHookStorageUpdate] = [] {
        willSet { ensureNotFrozen() }
    }

    /// Sets the fully-qualified ID of the hook whose storage is being updated.
    @discardableResult
    public func hookId(_ hookId: HookId) -> Self {
        self.hookId = hookId
        return self
    }

    /// Adds a single storage update to this transaction.
    @discardableResult
    public func addStorageUpdate(_ update: EvmHookStorageUpdate) -> Self {
        storageUpdates.append(update)
        return self
    }

    /// Sets all storage updates for this transaction, replacing any previously added.
    @discardableResult
    public func storageUpdates(_ updates: [EvmHookStorageUpdate]) -> Self {
        self.storageUpdates = updates
        return self
    }

    /// Removes all storage updates from this transaction.
    @discardableResult
    public func clearStorageUpdates() -> Self {
        storageUpdates.removeAll()
        return self
    }

    internal init(
        protobuf proto: Proto_TransactionBody,
        _ data: Com_Hedera_Hapi_Node_Hooks_HookStoreTransactionBody
    ) throws {
        self.hookId = try HookId(protobuf: data.hookID)
        self.storageUpdates = try data.storageUpdates.map { try EvmHookStorageUpdate(protobuf: $0) }
        try super.init(protobuf: proto)
    }

    internal override func validateChecksums(on ledgerId: LedgerId) throws {
        try hookId?.validateChecksums(on: ledgerId)
        try super.validateChecksums(on: ledgerId)
    }

    internal override func transactionExecute(
        _ channel: GRPCChannel,
        _ request: Proto_Transaction,
        _ deadline: TimeInterval
    ) async throws -> Proto_TransactionResponse {
        return try await Proto_SmartContractServiceAsyncClient(channel: channel)
            .hookStore(request, callOptions: applyGrpcHeader(deadline: deadline))
    }

    internal override func toTransactionDataProtobuf(_ chunkInfo: ChunkInfo) -> Proto_TransactionBody.OneOf_Data {
        _ = chunkInfo.assertSingleTransaction()
        return .hookStore(toProtobuf())
    }
}

extension HookStoreTransaction: ToProtobuf {
    internal typealias Protobuf = Com_Hedera_Hapi_Node_Hooks_HookStoreTransactionBody

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            if let id = hookId {
                proto.hookID = id.toProtobuf()
            }
            proto.storageUpdates = storageUpdates.map { $0.toProtobuf() }
        }
    }
}
