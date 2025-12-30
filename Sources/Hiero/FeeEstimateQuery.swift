// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

/// Request object for users, SDKs, and tools to query expected fees without
/// submitting transactions to the network.
///
/// This query uses the mirror node REST API to estimate fees for a transaction
/// before it is submitted. The transaction is automatically frozen if not already
/// frozen before the request is made.
///
/// ## Example Usage
/// ```swift
/// let query = FeeEstimateQuery()
///     .setTransaction(myTransaction)
///     .setMode(.state)
///
/// let response = try await query.execute(client)
/// print("Estimated fee: \(response.total) tinycents")
/// ```
public final class FeeEstimateQuery: ValidateChecksums {
    /// The fee estimation mode.
    private var mode: FeeEstimateMode

    /// The transaction to estimate fees for.
    private var transaction: Transaction?

    /// Create a new `FeeEstimateQuery`.
    ///
    /// - Parameters:
    ///   - mode: The estimation mode. Defaults to `.state` which uses the latest known network state.
    ///   - transaction: The transaction to estimate fees for. Can be set later via `setTransaction`.
    public init(mode: FeeEstimateMode = .state, transaction: Transaction? = nil) {
        self.mode = mode
        self.transaction = transaction
    }

    /// Get the current estimation mode.
    ///
    /// - Returns: The current `FeeEstimateMode`.
    public func getMode() -> FeeEstimateMode {
        mode
    }

    /// Set the estimation mode.
    ///
    /// - Parameter mode: The estimation mode. `.state` uses latest network state,
    ///   `.intrinsic` ignores state-dependent factors.
    /// - Returns: `self` for method chaining.
    @discardableResult
    public func setMode(_ mode: FeeEstimateMode) -> Self {
        self.mode = mode
        return self
    }

    /// Get the current transaction.
    ///
    /// - Returns: The transaction to estimate fees for, or `nil` if not set.
    public func getTransaction() -> Transaction? {
        transaction
    }

    /// Set the transaction to estimate fees for.
    ///
    /// - Parameter transaction: The transaction to estimate. Must be set before calling `execute`.
    /// - Returns: `self` for method chaining.
    @discardableResult
    public func setTransaction(_ transaction: Transaction) -> Self {
        self.transaction = transaction
        return self
    }

    /// Execute the fee estimate query.
    ///
    /// Sends the transaction to the mirror node REST API to get an estimated fee.
    /// The transaction is automatically frozen with the client if not already frozen.
    ///
    /// - Parameters:
    ///   - client: The client to use for the request. Provides mirror node configuration.
    ///   - timeout: Optional timeout for the HTTP request. If `nil`, uses system default.
    /// - Returns: The fee estimate response containing network, node, and service fees.
    /// - Throws: `HError.unitialized` if no transaction is set.
    /// - Throws: `HError.basicParse` if the mirror node request fails or returns invalid data.
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

        // Handle chunked transactions (e.g., FileAppendTransaction with large data)
        if let chunkedTransaction = transaction as? ChunkedTransaction {
            return try await estimateChunkedTransaction(chunkedTransaction, client, timeout: timeout)
        }

        // For non-chunked transactions, create a single transaction protobuf
        // Use dummy IDs if not set - the mirror node only needs the transaction structure for estimation
        let transactionId = transaction.transactionId ?? Transaction.dummyId
        let nodeAccountId = transaction.nodeAccountIds?.first ?? Transaction.dummyAccountId

        let chunkInfo = ChunkInfo.single(transactionId: transactionId, nodeAccountId: nodeAccountId)
        let (transactionProtobuf, _) = transaction.makeRequestInner(chunkInfo: chunkInfo)

        return try await requestFeeEstimate(client: client, transaction: transactionProtobuf, timeout: timeout)
    }

    // MARK: - Private Implementation

    /// Send a fee estimate request for a transaction to the mirror node REST API.
    ///
    /// - Parameters:
    ///   - client: The client providing mirror node configuration.
    ///   - transaction: The protobuf-encoded transaction to estimate.
    ///   - timeout: Optional request timeout.
    /// - Returns: The parsed fee estimate response.
    /// - Throws: Network or parsing errors.
    private func requestFeeEstimate(
        client: Client,
        transaction: Proto_Transaction,
        timeout: TimeInterval?
    ) async throws -> FeeEstimateResponse {
        // Serialize the transaction to protobuf bytes for the request body
        let transactionBytes = try transaction.serializedData()

        // Construct the mirror node URL
        let url = try buildFeeEstimateUrl(client: client)

        // Build the HTTP request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/protobuf", forHTTPHeaderField: "Content-Type")
        request.httpBody = transactionBytes

        // Apply timeout if provided
        if let timeout = timeout {
            request.timeoutInterval = timeout
        }

        // Send the request (platform-specific implementation)
        #if canImport(FoundationNetworking)
            // Linux: Use callback-based API wrapped in async continuation
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
            throw HError.basicParse("Fee estimate request failed: Invalid HTTP response")
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw HError.basicParse("Fee estimate request failed: HTTP \(httpResponse.statusCode) - \(errorMessage)")
        }

        // Parse JSON response
        return try FeeEstimateResponse.fromJson(data, mode: mode)
    }

    /// Build the URL for the fee estimate endpoint.
    ///
    /// - Parameter client: The client providing mirror node configuration.
    /// - Returns: The constructed URL for the fee estimate endpoint.
    /// - Throws: `HError.basicParse` if no mirror network is configured or URL is invalid.
    private func buildFeeEstimateUrl(client: Client) throws -> URL {
        guard let mirrorNetworkAddress = client.mirrorNetwork.first else {
            throw HError.basicParse("Fee estimate request failed: No mirror network configured")
        }

        let modeString = mode == .state ? "STATE" : "INTRINSIC"
        let endpoint = "/network/fees?mode=\(modeString)"

        // Check if this is a local development environment
        let isLocal = mirrorNetworkAddress.contains("localhost") || mirrorNetworkAddress.contains("127.0.0.1")

        let urlString: String
        if isLocal {
            // For local environments, use port 8084 for the mirror node REST API
            // (different from the default gRPC port)
            let host = mirrorNetworkAddress.split(separator: ":")[0]
            urlString = "http://\(host):8084\(endpoint)"
        } else {
            // For remote environments, use HTTPS with the configured address
            urlString = "https://\(mirrorNetworkAddress)\(endpoint)"
        }

        guard let url = URL(string: urlString) else {
            throw HError.basicParse("Fee estimate request failed: Invalid URL: \(urlString)")
        }

        return url
    }

    /// Estimate fees for a chunked transaction by estimating each chunk in parallel.
    ///
    /// Chunked transactions (like `FileAppendTransaction` with large data) are split into
    /// multiple network transactions. This method estimates the fee for each chunk and
    /// aggregates the results.
    ///
    /// - Parameters:
    ///   - transaction: The chunked transaction to estimate.
    ///   - client: The client providing mirror node configuration.
    ///   - timeout: Optional request timeout for each chunk request.
    /// - Returns: The aggregated fee estimate across all chunks.
    private func estimateChunkedTransaction(
        _ transaction: ChunkedTransaction,
        _ client: Client,
        timeout: TimeInterval?
    ) async throws -> FeeEstimateResponse {
        // Use dummy IDs if not set - the mirror node only needs the transaction structure
        let transactionId = transaction.transactionId ?? Transaction.dummyId
        let nodeAccountId = transaction.nodeAccountIds?.first ?? Transaction.dummyAccountId

        let usedChunks = transaction.usedChunks

        // Parallelize fee estimate requests for each chunk using a task group
        let responses = try await withThrowingTaskGroup(of: (Int, FeeEstimateResponse).self) { group in
            for chunkIndex in 0..<usedChunks {
                // Build chunk info for this specific chunk
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

                let (transactionProtobuf, _) = transaction.makeRequestInner(chunkInfo: chunkInfo)

                // Add task to estimate this chunk
                group.addTask {
                    let estimate = try await self.requestFeeEstimate(
                        client: client, transaction: transactionProtobuf, timeout: timeout)
                    return (chunkIndex, estimate)
                }
            }

            // Collect all results
            var results: [(Int, FeeEstimateResponse)] = []
            for try await result in group {
                results.append(result)
            }

            // Sort by chunk index to maintain deterministic ordering
            return results.sorted { $0.0 < $1.0 }.map { $1 }
        }

        return aggregateFeeResponses(responses)
    }

    /// Aggregate per-chunk fee responses into a single combined response.
    ///
    /// Sums the fees from each chunk while preserving the network multiplier from
    /// the first response (it should be consistent across chunks).
    ///
    /// - Parameter responses: The fee responses from each chunk.
    /// - Returns: A single aggregated fee response.
    private func aggregateFeeResponses(_ responses: [FeeEstimateResponse]) -> FeeEstimateResponse {
        // Handle empty responses edge case
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

        // Aggregate results across all chunks
        // Network multiplier should be consistent, so use the first one
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

    // MARK: - ValidateChecksums

    internal func validateChecksums(on ledgerId: LedgerId) throws {
        try transaction?.validateChecksums(on: ledgerId)
    }
}
