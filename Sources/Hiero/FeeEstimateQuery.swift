// SPDX-License-Identifier: Apache-2.0

import AnyAsyncSequence
import Foundation
import GRPC
import HieroProtobufs

/// Request object for users, SDKs, and tools to query expected fees without
/// submitting transactions to the network.
public final class FeeEstimateQuery: ValidateChecksums, MirrorQuery {
    private var mode: FeeEstimateMode
    private var transaction: Transaction?

    /// Create a new `FeeEstimateQuery`.
    public init(mode: FeeEstimateMode = .state, transaction: Transaction? = nil) {
        self.mode = mode
        self.transaction = transaction
    }

    /// Get the current estimation mode.
    public func getMode() -> FeeEstimateMode {
        mode
    }

    /// Set the estimation mode (optional, defaults to STATE).
    @discardableResult
    public func setMode(_ mode: FeeEstimateMode) -> Self {
        self.mode = mode
        return self
    }

    /// Get the current transaction.
    public func getTransaction() -> Transaction? {
        transaction
    }

    /// Set the transaction to estimate (required).
    @discardableResult
    public func setTransaction(_ transaction: Transaction) -> Self {
        self.transaction = transaction
        return self
    }

    public func subscribe(_ client: Client, _ timeout: TimeInterval? = nil) -> AnyAsyncSequence<FeeEstimateResponse> {
        // For unary RPC, subscribe just returns a single element
        // Use AsyncThrowingStream to handle errors properly
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let response = try await execute(client, timeout)
                    continuation.yield(response)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
        .eraseToAnyAsyncSequence()
    }

    public func execute(_ client: Client, _ timeout: TimeInterval? = nil) async throws -> FeeEstimateResponse {
        if client.isAutoValidateChecksumsEnabled() {
            try validateChecksums(on: client)
        }

        // Auto-freeze the transaction if not already frozen
        if let transaction = transaction, !transaction.isFrozen {
            try transaction.freezeWith(client)
        }

        return try await executeChannel(client.mirrorChannel, timeout)
    }

    internal func executeChannel(_ channel: any GRPCChannel, _ timeout: TimeInterval? = nil) async throws -> Response {
        guard let transaction = transaction else {
            throw HError.unitialized("Transaction is required for FeeEstimateQuery")
        }

        // Handle chunked transactions
        if let chunkedTransaction = transaction as? ChunkedTransaction {
            return try await estimateChunkedTransaction(chunkedTransaction, channel, timeout)
        }

        // For non-chunked transactions, create a single transaction protobuf
        // Transaction should already be frozen by execute() method, but handle the case where it's not
        let frozenTransaction = transaction.isFrozen ? transaction : try transaction.freeze()

        // Create a transaction protobuf using makeRequestInner
        // We'll use dummy values if needed since we're just estimating fees
        let transactionId = frozenTransaction.transactionId ?? Transaction.dummyId
        let nodeAccountId = frozenTransaction.nodeAccountIds?.first ?? Transaction.dummyAccountId

        let chunkInfo = ChunkInfo.single(transactionId: transactionId, nodeAccountId: nodeAccountId)
        let (transactionProtobuf, _) = frozenTransaction.makeRequestInner(chunkInfo: chunkInfo)

        let request = toProtobuf(transaction: transactionProtobuf)

        // Make the unary gRPC call with retry logic for transient errors
        // Note: This assumes the protobufs have been regenerated with getFeeEstimate method
        return try await executeWithRetry(channel: channel, request: request, timeout: timeout)
    }

    private func executeWithRetry(
        channel: any GRPCChannel,
        request: Protobuf,
        timeout: TimeInterval?
    ) async throws -> FeeEstimateResponse {
        let client = Com_Hedera_Mirror_Api_Proto_NetworkServiceAsyncClient(channel: channel)

        do {
            let response = try await client.getFeeEstimate(request)
            return try .fromProtobuf(response)
        } catch let error as GRPCStatus {
            // Retry on transient errors (UNAVAILABLE, DEADLINE_EXCEEDED)
            // Do not retry on INVALID_ARGUMENT (malformed transaction)
            switch error.code {
            case .unavailable, .deadlineExceeded:
                // Simple retry - in production, you might want exponential backoff
                let response = try await client.getFeeEstimate(request)
                return try .fromProtobuf(response)
            case .invalidArgument:
                // Don't retry on invalid arguments
                throw HError(
                    kind: .grpcStatus(status: Int32(error.code.rawValue)),
                    description: "Invalid transaction for fee estimation: \(error.message ?? "")"
                )
            default:
                throw HError(
                    kind: .grpcStatus(status: Int32(error.code.rawValue)),
                    description: error.message ?? ""
                )
            }
        }
    }

    private func estimateChunkedTransaction(
        _ transaction: ChunkedTransaction,
        _ channel: any GRPCChannel,
        _ timeout: TimeInterval?
    ) async throws -> FeeEstimateResponse {
        // Transaction should already be frozen by execute() method, but handle the case where it's not
        let frozenTransaction = transaction.isFrozen ? transaction : try transaction.freeze()

        guard let transactionId = frozenTransaction.transactionId ?? Transaction.dummyId as TransactionId?,
              let nodeAccountId = frozenTransaction.nodeAccountIds?.first ?? Transaction.dummyAccountId as AccountId?
        else {
            throw HError.unitialized("Transaction must have transaction ID and node account IDs for fee estimation")
        }

        let usedChunks = frozenTransaction.usedChunks

        var totalNodeSubtotal: UInt64 = 0
        var totalServiceSubtotal: UInt64 = 0
        var allNotes: [String] = []
        var networkMultiplier: UInt32 = 0
        var allNodeExtras: [FeeExtra] = []
        var allServiceExtras: [FeeExtra] = []

        // Estimate fees for each chunk
        for chunkIndex in 0..<usedChunks {
            let chunkInfo: ChunkInfo
            if chunkIndex == 0 {
                chunkInfo = ChunkInfo.initial(total: usedChunks, transactionId: transactionId, nodeAccountId: nodeAccountId)
            } else {
                // For subsequent chunks, we need to increment the transaction ID
                // In practice, the mirror node should handle this, but we'll use the same transaction ID
                // for estimation purposes
                chunkInfo = ChunkInfo(
                    current: chunkIndex,
                    total: usedChunks,
                    initialTransactionId: transactionId,
                    currentTransactionId: transactionId,
                    nodeAccountId: nodeAccountId
                )
            }

            let (transactionProtobuf, _) = frozenTransaction.makeRequestInner(chunkInfo: chunkInfo)
            let request = toProtobuf(transaction: transactionProtobuf)

            let estimate = try await executeWithRetry(channel: channel, request: request, timeout: timeout)

            totalNodeSubtotal += estimate.nodeFee.base + estimate.nodeFee.extras.reduce(0) { $0 + $1.subtotal }
            totalServiceSubtotal += estimate.serviceFee.base + estimate.serviceFee.extras.reduce(0) { $0 + $1.subtotal }
            allNotes.append(contentsOf: estimate.notes)
            networkMultiplier = estimate.networkFee.multiplier
            allNodeExtras.append(contentsOf: estimate.nodeFee.extras)
            allServiceExtras.append(contentsOf: estimate.serviceFee.extras)
        }

        // Calculate aggregated fees
        // Node fee: sum of all base fees plus extras
        let nodeExtrasTotal = allNodeExtras.reduce(0) { $0 + $1.subtotal }
        let nodeBaseTotal = totalNodeSubtotal - nodeExtrasTotal
        
        // Service fee: sum of all base fees plus extras
        let serviceExtrasTotal = allServiceExtras.reduce(0) { $0 + $1.subtotal }
        let serviceBaseTotal = totalServiceSubtotal - serviceExtrasTotal
        
        // Network fee: calculated from node subtotal
        let networkSubtotal = UInt64(networkMultiplier) * totalNodeSubtotal
        let total = networkSubtotal + totalNodeSubtotal + totalServiceSubtotal

        // Create aggregated response
        return FeeEstimateResponse(
            mode: mode,
            networkFee: NetworkFee(multiplier: networkMultiplier, subtotal: networkSubtotal),
            nodeFee: FeeEstimate(base: nodeBaseTotal, extras: allNodeExtras),
            serviceFee: FeeEstimate(base: serviceBaseTotal, extras: allServiceExtras),
            notes: Array(Set(allNotes)), // Deduplicate notes
            total: total
        )
    }

    internal func validateChecksums(on ledgerId: LedgerId) throws {
        // Validate transaction if present
        try transaction?.validateChecksums(on: ledgerId)
    }
}

extension FeeEstimateQuery: ToProtobuf {
    internal typealias Protobuf = Com_Hedera_Mirror_Api_Proto_FeeEstimateQuery

    internal func toProtobuf() -> Protobuf {
        // This method is required by ToProtobuf protocol but isn't typically used
        // since we need the transaction to create a complete protobuf.
        // Use toProtobuf(transaction:) instead for the actual implementation.
        .with { proto in
            proto.mode = mode.toProtobuf()
            // transaction field will be empty - caller should use toProtobuf(transaction:) instead
        }
    }

    internal func toProtobuf(transaction: Proto_Transaction) -> Protobuf {
        .with { proto in
            proto.mode = mode.toProtobuf()
            proto.transaction = transaction
        }
    }
}


