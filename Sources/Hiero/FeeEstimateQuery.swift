// SPDX-License-Identifier: Apache-2.0

import AnyAsyncSequence
import Foundation
import HieroProtobufs

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

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

        guard let transaction = transaction else {
            throw HError.unitialized("Transaction is required for FeeEstimateQuery")
        }

        // Auto-freeze the transaction if not already frozen
        if !transaction.isFrozen {
            try transaction.freezeWith(client)
        }

        // Handle chunked transactions
        if let chunkedTransaction = transaction as? ChunkedTransaction {
            return try await estimateChunkedTransaction(chunkedTransaction, client)
        }

        // For non-chunked transactions, create a single transaction protobuf
        let frozenTransaction = transaction.isFrozen ? transaction : try transaction.freeze()

        // Create a transaction protobuf using makeRequestInner
        let transactionId = frozenTransaction.transactionId ?? Transaction.dummyId
        let nodeAccountId = frozenTransaction.nodeAccountIds?.first ?? Transaction.dummyAccountId

        let chunkInfo = ChunkInfo.single(transactionId: transactionId, nodeAccountId: nodeAccountId)
        let (transactionProtobuf, _) = frozenTransaction.makeRequestInner(chunkInfo: chunkInfo)

        return try await requestFeeEstimate(client: client, transaction: transactionProtobuf)
    }

    /// Send a fee estimate request for a transaction to the mirror node REST API.
    private func requestFeeEstimate(
        client: Client,
        transaction: Proto_Transaction
    ) async throws -> FeeEstimateResponse {
        // Serialize the transaction to protobuf bytes
        let transactionBytes = try transaction.serializedData()

        // Construct the URL
        let url = try buildFeeEstimateUrl(client: client)

        // Build the HTTP request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/protobuf", forHTTPHeaderField: "Content-Type")
        request.httpBody = transactionBytes

        // Send the request
        #if canImport(FoundationNetworking)
            // Linux: Use callback-based API wrapped in continuation
            let (data, response): (Data, URLResponse) = try await withCheckedThrowingContinuation { continuation in
                URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    guard let data = data, let response = response else {
                        continuation.resume(throwing: URLError(.badServerResponse))
                        return
                    }
                    continuation.resume(returning: (data, response))
                }.resume()
            }
        #else
            // macOS/iOS: Use modern async/await API
            let (data, response) = try await URLSession.shared.data(for: request)
        #endif

        // Verify response status
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HError.basicParse("Invalid HTTP response")
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw HError.basicParse("HTTP error \(httpResponse.statusCode): \(errorMessage)")
        }

        // Parse JSON response
        return try FeeEstimateResponse.fromJson(data, mode: mode)
    }

    /// Build the URL for the fee estimate endpoint.
    private func buildFeeEstimateUrl(client: Client) throws -> URL {
        let mirrorNetworkAddress = client.mirrorNetwork[0]
        let modeString = mode == .state ? "STATE" : "INTRINSIC"
        let endpoint = "/network/fees?mode=\(modeString)"

        // Check if this is a local environment
        let isLocal = mirrorNetworkAddress.contains("localhost") || mirrorNetworkAddress.contains("127.0.0.1")

        let urlString: String
        if isLocal {
            // For local environments, use port 8084 for the mirror node REST API
            let host = mirrorNetworkAddress.split(separator: ":")[0]
            urlString = "http://\(host):8084\(endpoint)"
        } else {
            // For remote environments, use HTTPS
            urlString = "https://\(mirrorNetworkAddress)\(endpoint)"
        }

        guard let url = URL(string: urlString) else {
            throw HError.basicParse("Invalid URL: \(urlString)")
        }

        return url
    }

    /// Estimate fees for a chunked transaction.
    private func estimateChunkedTransaction(
        _ transaction: ChunkedTransaction,
        _ client: Client
    ) async throws -> FeeEstimateResponse {
        // Transaction should already be frozen by execute() method, but handle the case where it's not
        let frozenTransaction = transaction.isFrozen ? transaction : try transaction.freeze()

        guard let transactionId = frozenTransaction.transactionId ?? Transaction.dummyId as TransactionId?,
            let nodeAccountId = frozenTransaction.nodeAccountIds?.first ?? Transaction.dummyAccountId as AccountId?
        else {
            throw HError.unitialized(
                "Transaction must have transaction ID and node account IDs for fee estimation")
        }

        let usedChunks = frozenTransaction.usedChunks
        var responses: [FeeEstimateResponse] = []

        // Estimate fees for each chunk
        for chunkIndex in 0..<usedChunks {
            let chunkInfo: ChunkInfo
            if chunkIndex == 0 {
                chunkInfo = ChunkInfo.initial(
                    total: usedChunks, transactionId: transactionId, nodeAccountId: nodeAccountId)
            } else {
                chunkInfo = ChunkInfo(
                    current: chunkIndex,
                    total: usedChunks,
                    initialTransactionId: transactionId,
                    currentTransactionId: transactionId,
                    nodeAccountId: nodeAccountId
                )
            }

            let (transactionProtobuf, _) = frozenTransaction.makeRequestInner(chunkInfo: chunkInfo)
            let estimate = try await requestFeeEstimate(client: client, transaction: transactionProtobuf)
            responses.append(estimate)
        }

        return aggregateFeeResponses(responses)
    }

    /// Aggregate per-chunk fee responses into a single response.
    private func aggregateFeeResponses(_ responses: [FeeEstimateResponse]) -> FeeEstimateResponse {
        if responses.isEmpty {
            return FeeEstimateResponse(
                mode: mode,
                networkFee: NetworkFee(multiplier: 0, subtotal: 0),
                nodeFee: FeeEstimate(base: 0, extras: []),
                serviceFee: FeeEstimate(base: 0, extras: []),
                notes: [],
                total: 0
            )
        }

        // Aggregate results across chunks
        var networkMultiplier: UInt32 = responses[0].networkFee.multiplier
        var networkSubtotal: UInt64 = 0
        var nodeBase: UInt64 = 0
        var serviceBase: UInt64 = 0
        var allNodeExtras: [FeeExtra] = []
        var allServiceExtras: [FeeExtra] = []
        var allNotes: [String] = []
        var total: UInt64 = 0

        for response in responses {
            networkMultiplier = response.networkFee.multiplier
            networkSubtotal += response.networkFee.subtotal
            nodeBase += response.nodeFee.base
            serviceBase += response.serviceFee.base
            allNodeExtras.append(contentsOf: response.nodeFee.extras)
            allServiceExtras.append(contentsOf: response.serviceFee.extras)
            allNotes.append(contentsOf: response.notes)
            total += response.total
        }

        return FeeEstimateResponse(
            mode: mode,
            networkFee: NetworkFee(multiplier: networkMultiplier, subtotal: networkSubtotal),
            nodeFee: FeeEstimate(base: nodeBase, extras: allNodeExtras),
            serviceFee: FeeEstimate(base: serviceBase, extras: allServiceExtras),
            notes: allNotes,
            total: total
        )
    }

    internal func validateChecksums(on ledgerId: LedgerId) throws {
        // Validate transaction if present
        try transaction?.validateChecksums(on: ledgerId)
    }
}
