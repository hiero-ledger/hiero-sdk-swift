// SPDX-License-Identifier: Apache-2.0

import Foundation
import GRPC
import HieroProtobufs
import SwiftProtobuf

// MARK: - Execute Protocol

/// Protocol for executing transactions and queries against a Hiero network.
///
/// This protocol defines the interface for any operation that can be submitted to
/// the network, handling retries, node selection, and error recovery automatically.
internal protocol Execute {
    /// GRPC request message type
    associatedtype GrpcRequest: SwiftProtobuf.Message

    /// GRPC response message type
    associatedtype GrpcResponse: SwiftProtobuf.Message

    /// Context data preserved across retries
    associatedtype Context

    /// Final response type returned to the caller
    associatedtype Response

    /// Specific nodes to submit this request to, or nil for automatic selection.
    var nodeAccountIds: [AccountId]? { get }

    /// Explicitly set transaction ID, preventing automatic generation.
    var explicitTransactionId: TransactionId? { get }

    /// Whether this operation requires a transaction ID.
    var requiresTransactionId: Bool { get }

    /// Account paying for this transaction, if explicitly specified.
    var operatorAccountId: AccountId? { get }

    /// Whether to regenerate the transaction ID if it expires.
    var regenerateTransactionId: Bool? { get }

    /// Initial transaction ID for multi-chunked transactions.
    var firstTransactionId: TransactionId? { get }

    /// Index of this transaction in a multi-chunked sequence.
    var index: Int? { get }

    /// Determines whether to retry for a given pre-check status.
    ///
    /// - Parameter status: The pre-check status from the response
    /// - Returns: True if the request should be retried with backoff
    func shouldRetryPrecheck(forStatus status: Status) -> Bool

    /// Determines whether to retry an otherwise successful response.
    ///
    /// - Parameter response: The GRPC response
    /// - Returns: True if the request should be retried despite OK status
    func shouldRetry(forResponse response: GrpcResponse) -> Bool

    /// Creates a GRPC request for execution.
    ///
    /// Requests are cached per node until a TransactionExpired status occurs.
    ///
    /// - Parameters:
    ///   - transactionId: Transaction ID for this request, if applicable
    ///   - nodeAccountId: Account ID of the node that will execute this request
    /// - Returns: Tuple of (GRPC request, context for creating the response)
    /// - Throws: HError if request creation fails
    func makeRequest(_ transactionId: TransactionId?, _ nodeAccountId: AccountId) throws -> (GrpcRequest, Context)

    /// Executes the GRPC request on the specified channel.
    ///
    /// - Parameters:
    ///   - channel: GRPC channel to the target node
    ///   - request: The GRPC request to execute
    /// - Returns: GRPC response from the node
    /// - Throws: GRPCStatus or other errors during execution
    func execute(_ channel: GRPCChannel, _ request: GrpcRequest) async throws -> GrpcResponse

    /// Creates the final response from a successful GRPC response.
    ///
    /// - Parameters:
    ///   - response: The GRPC response
    ///   - context: Context data from makeRequest
    ///   - nodeAccountId: Account ID of the node that processed the request
    ///   - transactionId: Transaction ID used for the request
    /// - Returns: Final response object for the caller
    /// - Throws: HError if response creation fails
    func makeResponse(
        _ response: GrpcResponse,
        _ context: Context,
        _ nodeAccountId: AccountId,
        _ transactionId: TransactionId?
    ) throws -> Response

    /// Creates an error from a pre-check status.
    ///
    /// - Parameters:
    ///   - status: The pre-check status code
    ///   - transactionId: Transaction ID associated with the error
    /// - Returns: HError describing the failure
    func makeErrorPrecheck(_ status: Status, _ transactionId: TransactionId?) -> HError

    /// Extracts the pre-check status code from a GRPC response.
    ///
    /// - Parameter response: The GRPC response
    /// - Returns: Status code as Int32
    /// - Throws: HError if status cannot be extracted
    static func responsePrecheckStatus(_ response: GrpcResponse) throws -> Int32
}

// MARK: - Execute Protocol Defaults

extension Execute {
    /// Default: no retry based on pre-check status.
    internal func shouldRetryPrecheck(forStatus status: Status) -> Bool {
        false
    }

    /// Default: no retry for successful responses.
    internal func shouldRetry(forResponse response: GrpcResponse) -> Bool {
        false
    }

    /// Applies standard GRPC headers including SDK version.
    internal func applyGrpcHeader() -> CallOptions {
        return CallOptions(customMetadata: ["x-user-agent": "hiero-sdk-swift/" + VersionInfo.version])
    }
}

// MARK: - Execute Context

/// Internal context for executing requests with retry logic.
private struct ExecuteContext {
    /// Operator account ID, enables transaction ID regeneration on expiry if set
    let operatorAccountId: AccountId?

    /// Consensus network for node selection and health tracking
    let network: ConsensusNetwork

    /// Exponential backoff configuration for retries
    let backoffConfig: ExponentialBackoff

    /// Maximum number of attempts before giving up
    let maxAttempts: Int

    /// Timeout for a single GRPC request (currently unused)
    let grpcTimeout: Duration?
}

// MARK: - Public Execute Functions

/// Executes a transaction or query with automatic retries and error handling.
///
/// This function orchestrates the complete execution flow:
/// 1. Validates checksums if enabled
/// 2. Determines operator account and transaction ID regeneration settings
/// 3. Configures exponential backoff based on client settings
/// 4. Delegates to executeAnyInner for the actual execution
///
/// - Parameters:
///   - client: The client instance with network and configuration
///   - executable: The transaction or query to execute
///   - timeout: Maximum time to spend on execution, or nil for default
/// - Returns: The response from the successful execution
/// - Throws: HError if execution fails after all retries
internal func executeAny<E: Execute & ValidateChecksums>(
    _ client: Client, _ executable: E, _ timeout: TimeInterval?
)
    async throws -> E.Response
{
    let timeout = timeout ?? ExponentialBackoff.defaultMaxElapsedTime

    if client.isAutoValidateChecksumsEnabled() {
        try executable.validateChecksums(on: client)
    }

    let operatorAccountId: AccountId?

    // Where the operatorAccountId is set.
    // Determines if transactionId regeneration is disabled.
    do {
        if executable.explicitTransactionId != nil
            || !(executable.regenerateTransactionId ?? client.defaultRegenerateTransactionId)
        {
            operatorAccountId = nil
        } else {
            operatorAccountId =
                executable.firstTransactionId?.accountId ?? executable.operatorAccountId ?? client.operator?.accountId
        }
    }

    let backoff = client.backoff

    let backoffBuilder = ExponentialBackoff(
        initialInterval: backoff.initialBackoff,
        maxInterval: backoff.maxBackoff,
        maxElapsedTime: .limited(timeout)
    )

    return try await executeAnyInner(
        ctx: ExecuteContext(
            operatorAccountId: operatorAccountId,
            network: client.consensus,
            backoffConfig: backoffBuilder,
            maxAttempts: backoff.maxAttempts,
            grpcTimeout: nil
        ),
        executable: executable)
}

// MARK: - Execute Internal Implementation

/// Internal execution loop with retry logic and node selection.
///
/// Continuously attempts to execute the request across available nodes,
/// applying exponential backoff and node health tracking. Handles:
/// - Automatic node selection from healthy nodes
/// - Transaction ID regeneration on expiry
/// - GRPC errors and pre-check status handling
/// - Node health marking based on success/failure
///
/// - Parameters:
///   - ctx: Execution context with network and backoff config
///   - executable: The transaction or query to execute
/// - Returns: The response from successful execution
/// - Throws: HError if all attempts are exhausted
private func executeAnyInner<E: Execute>(
    ctx: ExecuteContext, executable: E
) async throws -> E.Response {
    let explicitTransactionId = executable.explicitTransactionId
    var backoff = ctx.backoffConfig
    var lastError: HError?

    var transactionId = generateInitialTransactionId(
        for: executable,
        explicitId: explicitTransactionId,
        operatorAccountId: ctx.operatorAccountId
    )

    let explicitNodeIndexes = try executable.nodeAccountIds.map { try ctx.network.nodeIndexes(for: $0) }
    var attempt = 0

    while true {
        let randomNodeIndexes = randomNodeIndexes(ctx: ctx, explicitNodeIndexes: explicitNodeIndexes)

        inner: for await nodeIndex in randomNodeIndexes {
            defer { attempt += 1 }

            if attempt >= ctx.maxAttempts {
                throw HError.timedOut(String(describing: lastError))
            }

            let result = try await executeOnNode(
                nodeIndex: nodeIndex,
                ctx: ctx,
                executable: executable,
                transactionId: transactionId
            )

            switch result {
            case .success(let response):
                return response

            case .retryWithBackoff(let error):
                lastError = error
                break inner

            case .retryImmediately(let error):
                lastError = error
                continue inner

            case .regenerateTransactionAndRetry(let error):
                lastError = error
                transactionId = regenerateTransactionId(
                    for: executable,
                    explicitId: explicitTransactionId,
                    operatorAccountId: ctx.operatorAccountId
                )
                continue inner
            }
        }

        guard let timeout = backoff.next() else {
            throw HError.timedOut(String(describing: lastError))
        }

        try await Task.sleep(nanoseconds: timeout.nanoseconds)
    }
}

// MARK: - Execution Result Type

/// Result of attempting to execute a request on a node.
private enum ExecutionResult<Response> {
    /// Request succeeded with a response
    case success(Response)

    /// Request failed and should be retried with exponential backoff
    case retryWithBackoff(HError)

    /// Request failed and should be retried immediately on next node
    case retryImmediately(HError)

    /// Transaction expired and should be retried with a new transaction ID
    case regenerateTransactionAndRetry(HError)
}

// MARK: - Transaction ID Management

/// Generates the initial transaction ID for a request.
///
/// Priority order:
/// 1. Explicit transaction ID (if set)
/// 2. Generated from first transaction ID (for chunked transactions)
/// 3. Generated from executable's operator account ID
/// 4. Generated from context's operator account ID
///
/// - Parameters:
///   - executable: The transaction or query being executed
///   - explicitId: Explicitly set transaction ID, if any
///   - operatorAccountId: Operator account from execution context
/// - Returns: Generated or explicit transaction ID, or nil if not required
private func generateInitialTransactionId<E: Execute>(
    for executable: E,
    explicitId: TransactionId?,
    operatorAccountId: AccountId?
) -> TransactionId? {
    guard executable.requiresTransactionId else {
        return nil
    }

    return explicitId
        ?? TransactionId.generateFromInitial(executable.firstTransactionId, executable.index)
        ?? executable.operatorAccountId.map(TransactionId.generateFrom)
        ?? operatorAccountId.map(TransactionId.generateFrom)
}

/// Regenerates a transaction ID when the previous one expired.
///
/// Only regenerates if there's no explicit transaction ID and an operator account is available.
///
/// - Parameters:
///   - executable: The transaction or query being executed
///   - explicitId: Explicitly set transaction ID (prevents regeneration if present)
///   - operatorAccountId: Operator account to generate from
/// - Returns: New transaction ID, or nil if regeneration is not possible/allowed
private func regenerateTransactionId<E: Execute>(
    for executable: E,
    explicitId: TransactionId?,
    operatorAccountId: AccountId?
) -> TransactionId? {
    guard explicitId == nil, let accountId = executable.operatorAccountId ?? operatorAccountId else {
        return nil
    }
    return .generateFrom(accountId)
}

// MARK: - Node Execution

/// Executes a request on a specific node and returns the categorized result.
///
/// Handles both GRPC-level errors and Hedera pre-check status errors,
/// marking node health appropriately.
///
/// - Parameters:
///   - nodeIndex: Index of the node to execute on
///   - ctx: Execution context
///   - executable: The transaction or query to execute
///   - transactionId: Transaction ID for this attempt
/// - Returns: Execution result indicating success or type of retry needed
/// - Throws: HError for unrecoverable errors
private func executeOnNode<E: Execute>(
    nodeIndex: Int,
    ctx: ExecuteContext,
    executable: E,
    transactionId: TransactionId?
) async throws -> ExecutionResult<E.Response> {
    let (nodeAccountId, channel) = ctx.network.channel(for: nodeIndex)
    let (request, context) = try executable.makeRequest(transactionId, nodeAccountId)

    let response: E.GrpcResponse
    do {
        response = try await executable.execute(channel, request)
    } catch let error as GRPCStatus {
        return try handleGrpcError(error, nodeIndex: nodeIndex, ctx: ctx)
    }

    ctx.network.markNodeHealthy(at: nodeIndex)

    let rawPrecheckStatus = try E.responsePrecheckStatus(response)
    let precheckStatus = Status(rawValue: rawPrecheckStatus)

    return try handlePrecheckStatus(
        precheckStatus,
        response: response,
        context: context,
        nodeAccountId: nodeAccountId,
        transactionId: transactionId,
        executable: executable,
        ctx: ctx
    )
}

// MARK: - Error Handling

/// Handles GRPC-level errors and determines retry strategy.
///
/// Marks nodes as unhealthy when they return unavailable or resource exhausted errors.
///
/// - Parameters:
///   - error: The GRPC status error
///   - nodeIndex: Index of the node that returned the error
///   - ctx: Execution context
/// - Returns: Execution result for retry decision
/// - Throws: HError for non-retryable GRPC errors
private func handleGrpcError<Response>(
    _ error: GRPCStatus,
    nodeIndex: Int,
    ctx: ExecuteContext
) throws -> ExecutionResult<Response> {
    let hError = HError(
        kind: .grpcStatus(status: Int32(error.code.rawValue)),
        description: error.description
    )

    switch error.code {
    case .unavailable, .resourceExhausted:
        ctx.network.markNodeUnhealthy(at: nodeIndex)
        return .retryImmediately(hError)
    default:
        throw hError
    }
}

/// Handles Hedera pre-check status codes and determines retry strategy.
///
/// Categories of handling:
/// - `ok`: Success, unless custom retry logic says otherwise
/// - `busy`, `platformNotActive`: Retry immediately on another node
/// - `transactionExpired`: Regenerate transaction ID if allowed
/// - `unrecognized`: Throw error for unknown status codes
/// - Custom retry statuses: Retry with backoff
/// - Everything else: Throw error
///
/// - Parameters:
///   - status: Parsed pre-check status
///   - response: GRPC response containing the status
///   - context: Context data from request creation
///   - nodeAccountId: Account ID of the node
///   - transactionId: Transaction ID used for the request
///   - executable: The transaction or query being executed
///   - ctx: Execution context
/// - Returns: Execution result indicating success or retry strategy
/// - Throws: HError for unrecoverable status codes
private func handlePrecheckStatus<E: Execute>(
    _ status: Status,
    response: E.GrpcResponse,
    context: E.Context,
    nodeAccountId: AccountId,
    transactionId: TransactionId?,
    executable: E,
    ctx: ExecuteContext
) throws -> ExecutionResult<E.Response> {
    switch status {
    case .ok where executable.shouldRetry(forResponse: response):
        return .retryWithBackoff(executable.makeErrorPrecheck(status, transactionId))

    case .ok:
        let response = try executable.makeResponse(response, context, nodeAccountId, transactionId)
        return .success(response)

    case .busy, .platformNotActive:
        return .retryImmediately(executable.makeErrorPrecheck(status, transactionId))

    case .transactionExpired where executable.explicitTransactionId == nil && ctx.operatorAccountId != nil:
        return .regenerateTransactionAndRetry(executable.makeErrorPrecheck(status, transactionId))

    case .unrecognized(let value):
        throw HError(
            kind: .responseStatusUnrecognized,
            description: "response status \(value) unrecognized"
        )

    case let status where executable.shouldRetryPrecheck(forStatus: status):
        return .retryWithBackoff(executable.makeErrorPrecheck(status, transactionId))

    default:
        throw executable.makeErrorPrecheck(status, transactionId)
    }
}

// MARK: - Node Selection

/// Generates a random selection of indexes without replacement.
///
/// Uses optimized Fisher-Yates sampling to select `amount` unique random indexes
/// from the range [0, count). Uses swap+pop instead of remove for O(n) complexity.
///
/// - Parameters:
///   - count: Upper bound (exclusive) for index range
///   - amount: Number of unique indexes to select
/// - Returns: Array of randomly selected unique indexes
internal func randomIndexes(upTo count: Int, amount: Int) -> [Int] {
    guard amount > 0 && count > 0 else { return [] }

    var elements = Array(0..<count)
    var output: [Int] = []
    output.reserveCapacity(amount)

    let sampleSize = min(amount, count)

    for _ in 0..<sampleSize {
        let remainingCount = elements.count
        let randomIndex = Int.random(in: 0..<remainingCount)

        // Swap the selected element to the end, then pop it
        elements.swapAt(randomIndex, remainingCount - 1)
        output.append(elements.popLast()!)
    }

    return output
}

/// Async sequence that provides node indexes for execution, with optional health checking via ping.
///
/// This sequence processes node indexes and may ping nodes to verify their health before returning them.
/// When `passthrough` is true, indexes are returned without health checks.
private struct NodeIndexSequence: AsyncSequence, AsyncIteratorProtocol {
    typealias Element = Int
    typealias AsyncIterator = Self

    func makeAsyncIterator() -> AsyncIterator {
        self
    }

    init(indexes: [Int], passthrough: Bool, ctx: ExecuteContext) {
        // Using reversed array for efficient popLast() operations
        self.source = indexes.reversed()
        self.passthrough = passthrough
        self.ctx = ctx
    }

    private var source: [Int]
    private let passthrough: Bool
    private let ctx: ExecuteContext

    mutating func next() async -> Int? {
        guard let current = source.popLast() else {
            return nil
        }

        // Skip health checks when explicit nodes are specified
        if passthrough {
            return current
        }

        // Return immediately if node was recently pinged
        if ctx.network.nodeRecentlyPinged(at: current, now: .now) {
            return current
        }

        // Verify node health via ping
        if await pingNode(index: current, context: ctx) {
            return current
        }

        return nil
    }

    /// Pings a node to verify it's reachable and healthy
    private func pingNode(index: Int, context: ExecuteContext) async -> Bool {
        let request = PingQuery(nodeAccountId: context.network.nodes[index])

        let result: ()? = try? await executeAnyInner(
            ctx: ExecuteContext(
                operatorAccountId: nil,
                network: context.network,
                backoffConfig: context.backoffConfig,
                maxAttempts: context.maxAttempts,
                grpcTimeout: context.grpcTimeout
            ),
            executable: request
        )

        return result != nil
    }
}

/// Creates a sequence of randomized node indexes for execution.
///
/// When explicit nodes are provided, all are used without health checks.
/// Otherwise, approximately 2/3 of healthy nodes are randomly selected and health-checked.
///
/// The 2/3 sampling ratio balances load distribution across nodes with limiting
/// unnecessary network calls. For example, with 10 nodes, we'll try 7 of them
/// (rounded up via `(10 + 2) / 3`).
///
/// - Parameters:
///   - ctx: Execution context with network information
///   - explicitNodeIndexes: Specific nodes to use, or nil for automatic selection
/// - Returns: Async sequence of node indexes, with health checking when auto-selecting
private func randomNodeIndexes(ctx: ExecuteContext, explicitNodeIndexes: [Int]?) -> NodeIndexSequence {
    let nodeIndexes = explicitNodeIndexes ?? ctx.network.healthyNodeIndexes()

    // Select approximately 2/3 of nodes for execution attempts
    // This balances load distribution with limiting unnecessary network overhead
    let nodeSampleAmount =
        (explicitNodeIndexes != nil)
        ? nodeIndexes.count
        : (nodeIndexes.count + 2) / 3  // Integer division: (n+2)/3 rounds up properly

    let randomNodeIndexes = randomIndexes(upTo: nodeIndexes.count, amount: nodeSampleAmount).map { nodeIndexes[$0] }

    return NodeIndexSequence(indexes: randomNodeIndexes, passthrough: explicitNodeIndexes != nil, ctx: ctx)
}
