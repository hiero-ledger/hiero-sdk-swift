// SPDX-License-Identifier: Apache-2.0

import Foundation
import GRPC
import HieroProtobufs

/// Updates storage for a Lambda EVM hook.
public final class LambdaSStoreTransaction: Transaction {
    /// Create a new `LambdaSStoreTransaction` ready for configuration.
    public override init() {
        super.init()
    }

    /// The ID of the hook to update.
    public var hookId: HookId? {
        willSet { ensureNotFrozen() }
    }

    /// The storage updates to apply to the hook.
    public var storageUpdates: [LambdaStorageUpdate] = [] {
        willSet { ensureNotFrozen() }
    }

    /// Sets the ID of the hook to update.
    @discardableResult
    public func hookId(_ hookId: HookId) -> Self {
        self.hookId = hookId
        return self
    }

    /// Adds a storage update.
    @discardableResult
    public func addStorageUpdate(_ update: LambdaStorageUpdate) -> Self {
        storageUpdates.append(update)
        return self
    }

    /// Sets all storage updates.
    @discardableResult
    public func storageUpdates(_ updates: [LambdaStorageUpdate]) -> Self {
        self.storageUpdates = updates
        return self
    }

    /// Clears all storage updates.
    @discardableResult
    public func clearStorageUpdates() -> Self {
        storageUpdates.removeAll()
        return self
    }

    /// Construct from `TransactionBody` and the concrete Lambda SSTORE body.
    internal init(
        protobuf proto: Proto_TransactionBody,
        _ data: Com_Hedera_Hapi_Node_Hooks_LambdaSStoreTransactionBody
    ) throws {
        // hookID (message presence); treat default instance as nil if your SDK does that.
        self.hookId = try HookId(protobuf: data.hookID)

        // storageUpdates (repeated)
        self.storageUpdates = try data.storageUpdates.map { try LambdaStorageUpdate(protobuf: $0) }

        try super.init(protobuf: proto)
    }

    internal override func validateChecksums(on ledgerId: LedgerId) throws {
        // If HookId/HookEntityId/AccountId supports checksum validation, invoke it here.
        // Example (adjust to your actual API):
        // try hookId?.entityId.accountId?.validateChecksums(on: ledgerId)
        try super.validateChecksums(on: ledgerId)
    }

    internal override func transactionExecute(
        _ channel: GRPCChannel,
        _ request: Proto_Transaction
    ) async throws -> Proto_TransactionResponse {
        // TODO: Adjust the service/type name to your generated gRPC client and method.
        // This is the conventional naming SwiftProtobuf generates for a `HooksService` with rpc `lambdaSStore`.
        return try await Proto_SmartContractServiceAsyncClient(channel: channel)
            .lambdaSStore(request, callOptions: applyGrpcHeader())
    }

    internal override func toTransactionDataProtobuf(_ chunkInfo: ChunkInfo) -> Proto_TransactionBody.OneOf_Data {
        _ = chunkInfo.assertSingleTransaction()
        return .lambdaSstore(toProtobuf())
    }
}

extension LambdaSStoreTransaction: ToProtobuf {
    internal typealias Protobuf = Com_Hedera_Hapi_Node_Hooks_LambdaSStoreTransactionBody

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            if let id = hookId {
                proto.hookID = id.toProtobuf()
            }
            proto.storageUpdates = storageUpdates.map { $0.toProtobuf() }
        }
    }
}
