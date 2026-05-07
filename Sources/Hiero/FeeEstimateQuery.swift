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
///     .transaction(myTransaction)
///     .mode(.state)
///
/// let response = try await query.execute(client)
/// print("Estimated fee: \(response.total) tinycents")
/// ```
public final class FeeEstimateQuery: ValidateChecksums {
    /// The fee estimation mode. Defaults to `.intrinsic`.
    public var mode: FeeEstimateMode = .intrinsic

    /// The transaction to estimate fees for.
    public var transaction: Transaction?

    /// High-volume throttle utilization in basis points (0–10000). Maps to the
    /// `high_volume_throttle` query parameter. 0 means no high-volume simulation.
    public var highVolumeThrottle: UInt16 = 0

    /// URLSession used for HTTP requests. Overridable in tests.
    internal var urlSession: URLSession = .shared

    /// Create a new `FeeEstimateQuery`.
    ///
    /// - Parameters:
    ///   - mode: The estimation mode. Defaults to `.intrinsic` which estimates from the payload alone.
    ///   - transaction: The transaction to estimate fees for. Can be set later via `transaction(_:)`.
    public init(mode: FeeEstimateMode = .intrinsic, transaction: Transaction? = nil) {
        self.mode = mode
        self.transaction = transaction
    }

    /// Sets the estimation mode.
    ///
    /// - Parameter mode: `.state` uses latest network state; `.intrinsic` ignores state-dependent factors.
    /// - Returns: `self` for method chaining.
    @discardableResult
    public func mode(_ mode: FeeEstimateMode) -> Self {
        self.mode = mode
        return self
    }

    /// Sets the transaction to estimate fees for.
    ///
    /// - Parameter transaction: The transaction to estimate. Must be set before calling `execute`.
    /// - Returns: `self` for method chaining.
    @discardableResult
    public func transaction(_ transaction: Transaction) -> Self {
        self.transaction = transaction
        return self
    }

    /// Sets the high-volume throttle utilization in basis points (0–10000, where 10000 = 100%).
    ///
    /// Simulates high-volume pricing conditions. A value of 0 (default) sends no parameter
    /// and the mirror node returns `highVolumeMultiplier: 1` (no high-volume pricing).
    /// - Returns: `self` for method chaining.
    @discardableResult
    public func highVolumeThrottle(_ throttle: UInt16) -> Self {
        self.highVolumeThrottle = throttle
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

    /// Wraps a retryable HTTP error so the retry loop can distinguish it from fatal errors.
    private struct RetryableHTTPError: Error {
        let underlying: HError
    }

    /// Send a fee estimate request for a transaction to the mirror node REST API.
    ///
    /// Retries on HTTP 500/503 and request timeout errors up to `client.maxAttempts`.
    /// Does not retry on HTTP 400 (malformed transaction).
    private func requestFeeEstimate(
        client: Client,
        transaction: Proto_Transaction,
        timeout: TimeInterval?
    ) async throws -> FeeEstimateResponse {
        let request = try buildURLRequest(client: client, transaction: transaction, timeout: timeout)
        let maxAttempts = client.maxAttempts
        var attempt = 0
        var lastError: Error = HError.basicParse("Fee estimate request failed: No attempts made")

        while attempt < maxAttempts {
            attempt += 1
            do {
                let (data, response) = try await performHTTPRequest(request)
                return try handleHTTPResponse(response, data: data)
            } catch let retryable as RetryableHTTPError {
                lastError = retryable.underlying
            } catch let urlError as URLError where urlError.code == .timedOut {
                lastError = urlError
            }
            if attempt < maxAttempts {
                try await Task.sleep(nanoseconds: backoffNanoseconds(attempt: attempt, client: client))
            }
        }

        throw lastError
    }

    /// Build the URLRequest for a fee estimate POST.
    private func buildURLRequest(
        client: Client,
        transaction: Proto_Transaction,
        timeout: TimeInterval?
    ) throws -> URLRequest {
        let transactionBytes = try transaction.serializedData()
        let url = try buildFeeEstimateUrl(client: client)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/protobuf", forHTTPHeaderField: "Content-Type")
        request.httpBody = transactionBytes
        if let timeout = timeout {
            request.timeoutInterval = timeout
        }
        return request
    }

    /// Validate an HTTP response and parse it into a `FeeEstimateResponse`.
    ///
    /// Throws `RetryableHTTPError` for HTTP 500/503 so the caller can retry.
    /// Throws `HError` directly for HTTP 400 and other non-2xx codes.
    private func handleHTTPResponse(_ response: URLResponse, data: Data) throws -> FeeEstimateResponse {
        guard let http = response as? HTTPURLResponse else {
            throw HError.basicParse("Fee estimate request failed: Invalid HTTP response")
        }
        let body = String(data: data, encoding: .utf8) ?? "Unknown error"
        if http.statusCode == 400 {
            throw HError.basicParse("Fee estimate request failed: HTTP 400 - \(body)")
        }
        // HTTP 500 or 503: retryable — mirror node spec uses 500 for service unavailability;
        // 503 covers reverse-proxy scenarios.
        if http.statusCode == 500 || http.statusCode == 503 {
            throw RetryableHTTPError(
                underlying: HError.basicParse(
                    "Fee estimate request failed: HTTP \(http.statusCode) - \(body)"))
        }
        guard (200..<300).contains(http.statusCode) else {
            throw HError.basicParse("Fee estimate request failed: HTTP \(http.statusCode) - \(body)")
        }
        return try FeeEstimateResponse.fromJson(data)
    }

    /// Perform a single HTTP request, using the appropriate URLSession API for the platform.
    private func performHTTPRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        #if canImport(FoundationNetworking)
            // Linux: Use callback-based API wrapped in async continuation
            return try await withCheckedThrowingContinuation { continuation in
                urlSession.dataTask(with: request) { data, response, error in
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
            return try await urlSession.data(for: request)
        #endif
    }

    /// Compute an exponential backoff delay for a given attempt number, capped to the client's `maxBackoff`.
    private func backoffNanoseconds(attempt: Int, client: Client) -> UInt64 {
        let initialBackoff = client.minBackoff
        let maxBackoff = client.maxBackoff
        let delay = min(initialBackoff * pow(2.0, Double(attempt - 1)), maxBackoff)
        return UInt64(delay * 1_000_000_000)
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
        var endpoint = "/api/v1/network/fees?mode=\(modeString)"
        if highVolumeThrottle > 0 {
            endpoint += "&high_volume_throttle=\(highVolumeThrottle)"
        }

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
    internal func aggregateFeeResponses(_ responses: [FeeEstimateResponse]) -> FeeEstimateResponse {
        // Handle empty responses edge case
        if responses.isEmpty {
            return FeeEstimateResponse(
                network: NetworkFee(multiplier: 0, subtotal: 0),
                node: FeeEstimate(base: 0, extras: []),
                service: FeeEstimate(base: 0, extras: []),
                total: 0
            )
        }

        // Aggregate results across all chunks.
        // Multiplier and highVolumeMultiplier should be consistent across chunks — capture from first response.
        let networkMultiplier: UInt32 = responses[0].network.multiplier
        let highVolumeMultiplier: UInt64 = responses[0].highVolumeMultiplier
        var nodeBase: UInt64 = 0
        var serviceBase: UInt64 = 0
        var allNodeExtras: [FeeExtra] = []
        var allServiceExtras: [FeeExtra] = []
        var total: UInt64 = 0

        for response in responses {
            nodeBase += response.node.base
            serviceBase += response.service.base
            allNodeExtras.append(contentsOf: response.node.extras)
            allServiceExtras.append(contentsOf: response.service.extras)
            total += response.total
        }

        // network.subtotal is computed from the aggregated node subtotal and network.multiplier.
        let aggregatedNodeSubtotal = nodeBase + allNodeExtras.reduce(0) { $0 + $1.subtotal }
        let networkSubtotal = UInt64(networkMultiplier) * aggregatedNodeSubtotal

        return FeeEstimateResponse(
            highVolumeMultiplier: highVolumeMultiplier,
            network: NetworkFee(multiplier: networkMultiplier, subtotal: networkSubtotal),
            node: FeeEstimate(base: nodeBase, extras: allNodeExtras),
            service: FeeEstimate(base: serviceBase, extras: allServiceExtras),
            total: total
        )
    }

    // MARK: - ValidateChecksums

    internal func validateChecksums(on ledgerId: LedgerId) throws {
        try transaction?.validateChecksums(on: ledgerId)
    }
}
