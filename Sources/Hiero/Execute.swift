// SPDX-License-Identifier: Apache-2.0

import Foundation
import GRPC
import HieroProtobufs
import SwiftProtobuf

internal protocol Execute {
    associatedtype GrpcRequest: SwiftProtobuf.Message
    associatedtype GrpcResponse: SwiftProtobuf.Message
    associatedtype Context
    associatedtype Response

    /// The _explicit_ nodes that this request will be submitted to.
    var nodeAccountIds: [AccountId]? { get }

    var explicitTransactionId: TransactionId? { get }

    var requiresTransactionId: Bool { get }

    /// ID for the account paying for this transaction, if explicitly specified.
    var operatorAccountId: AccountId? { get }

    /// Whether or not the transaction ID should be refreshed if a ``Status/transactionExpired`` occurs.
    var regenerateTransactionId: Bool? { get }

    /// The initial transaction Id value (for chunked transaction)
    /// Note: Used for multi-chunked transactions
    var firstTransactionId: TransactionId? { get }

    /// The index of each transactions
    /// Note: Used for multi-chunked transactions
    var index: Int? { get }

    /// Check whether to retry for a given pre-check status.
    func shouldRetryPrecheck(forStatus status: Status) -> Bool

    /// Check whether we should retry an otherwise successful response.
    func shouldRetry(forResponse response: GrpcResponse) -> Bool

    /// Create a new request for execution.
    ///
    /// A created request is cached per node until any request returns
    /// `TransactionExpired`; in which case, the request cache is cleared.
    func makeRequest(_ transactionId: TransactionId?, _ nodeAccountId: AccountId) throws -> (GrpcRequest, Context)

    func execute(_ channel: GRPCChannel, _ request: GrpcRequest) async throws -> GrpcResponse

    /// Create a response from the GRPC response and the saved transaction
    /// and node account ID from the successful request.
    func makeResponse(
        _ response: GrpcResponse,
        _ context: Context,
        _ nodeAccountId: AccountId,
        _ transactionId: TransactionId?
    ) throws -> Response

    func makeErrorPrecheck(_ status: Status, _ transactionId: TransactionId?) -> HError

    /// Gets pre-check status from the GRPC response.
    static func responsePrecheckStatus(_ response: GrpcResponse) throws -> Int32
}

extension Execute {
    internal func shouldRetryPrecheck(forStatus status: Status) -> Bool {
        false
    }

    internal func shouldRetry(forResponse response: GrpcResponse) -> Bool {
        false
    }

    internal func applyGrpcHeader() -> CallOptions {
        return CallOptions(customMetadata: ["x-user-agent": "hiero-sdk-swift/v0.39.0"])
    }
}

private struct ExecuteContext {
    // When not `nil` the `transactionId` will be regenerated when expired.
    fileprivate let operatorAccountId: AccountId?
    fileprivate let network: Network
    fileprivate let backoffConfig: LegacyExponentialBackoff
    fileprivate let maxAttempts: Int
    // timeout for a single grpc request.
    fileprivate let grpcTimeout: Duration?
}

internal func executeAny<E: Execute & ValidateChecksums>(
    _ client: Client, _ executable: E, _ timeout: TimeInterval?
)
    async throws -> E.Response
{
    let timeout = timeout ?? LegacyExponentialBackoff.defaultMaxElapsedTime

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

    let backoffBuilder = LegacyExponentialBackoff(
        initialInterval: backoff.initialBackoff,
        maxInterval: backoff.maxBackoff,
        maxElapsedTime: .limited(timeout)
    )

    // let backoff = client.backoff();
    // let mut backoff_builder = ExponentialBackoffBuilder::new();

    // backoff_builder
    //     .with_initial_interval(backoff.initial_backoff)
    //     .with_max_interval(backoff.max_backoff);

    // if let Some(timeout) = timeout.or(backoff.request_timeout) {
    //     backoff_builder.with_max_elapsed_time(Some(timeout));
    // }

    return try await executeAnyInner(
        ctx: ExecuteContext(
            operatorAccountId: operatorAccountId,
            network: client.net,
            backoffConfig: backoffBuilder,
            maxAttempts: backoff.maxAttempts,
            grpcTimeout: nil
        ),
        executable: executable)
}

private func executeAnyInner<E: Execute>(
    ctx: ExecuteContext, executable: E
) async throws -> E.Response {
    let explicitTransactionId = executable.explicitTransactionId

    var backoff = ctx.backoffConfig
    var lastError: HError?

    var transactionId =
        executable.requiresTransactionId
        ? (explicitTransactionId ?? TransactionId.generateFromInitial(executable.firstTransactionId, executable.index)
            ?? executable
            .operatorAccountId.map(TransactionId.generateFrom)
            ?? ctx.operatorAccountId.map(TransactionId.generateFrom)) : nil

    let explicitNodeIndexes = try executable.nodeAccountIds.map(ctx.network.nodeIndexesForIds)
    var attempt = 0

    while true {
        let randomNodeIndexes = randomNodeIndexes(ctx: ctx, explicitNodeIndexes: explicitNodeIndexes)
        inner: for await nodeIndex in randomNodeIndexes {
            defer {
                attempt += 1
            }

            if attempt >= ctx.maxAttempts {
                throw HError.timedOut(String(describing: lastError))
            }

            let (nodeAccountId, channel) = ctx.network.channel(for: nodeIndex)
            let (request, context) = try executable.makeRequest(transactionId, nodeAccountId)
            let response: E.GrpcResponse

            do {
                response = try await executable.execute(channel, request)

            } catch let error as GRPCStatus {
                switch error.code {
                case .unavailable, .resourceExhausted:
                    ctx.network.markNodeUnhealthy(nodeIndex)
                    // NOTE: this is an "unhealthy" node
                    // try the next node in our allowed list, immediately
                    lastError = HError(
                        kind: .grpcStatus(status: Int32(error.code.rawValue)),
                        description: error.description
                    )
                    continue inner

                case let code:
                    throw HError(
                        kind: .grpcStatus(status: Int32(code.rawValue)),
                        description: error.description
                    )
                }
            }

            ctx.network.markNodeHealthy(nodeIndex)

            let rawPrecheckStatus = try E.responsePrecheckStatus(response)
            let precheckStatus = Status(rawValue: rawPrecheckStatus)

            switch precheckStatus {
            case .ok where executable.shouldRetry(forResponse: response):
                lastError = executable.makeErrorPrecheck(precheckStatus, transactionId)
                break inner

            case .ok:
                return try executable.makeResponse(response, context, nodeAccountId, transactionId)

            case .busy, .platformNotActive:
                // NOTE: this is a "busy" node
                // try the next node in our allowed list, immediately
                lastError = executable.makeErrorPrecheck(precheckStatus, transactionId)

            case .transactionExpired
            where explicitTransactionId == nil
                && ctx.operatorAccountId != nil:
                // the transaction that was generated has since expired
                // re-generate the transaction ID and try again, immediately

                lastError = executable.makeErrorPrecheck(precheckStatus, transactionId)
                transactionId =
                    executable.operatorAccountId.map(TransactionId.generateFrom)
                    ?? .generateFrom(ctx.operatorAccountId!)
                continue inner

            case .unrecognized(let value):
                throw HError(
                    kind: .responseStatusUnrecognized,
                    description: "response status \(value) unrecognized"
                )

            case let status where executable.shouldRetryPrecheck(forStatus: precheckStatus):
                // conditional retry on pre-check should back-off and try again
                lastError = executable.makeErrorPrecheck(status, transactionId)
                break inner

            default:
                throw executable.makeErrorPrecheck(precheckStatus, transactionId)
            }
        }

        guard let timeout = backoff.next() else {
            throw HError.timedOut(String(describing: lastError))
        }

        try await Task.sleep(nanoseconds: UInt64(timeout * 1e9))
    }
}

internal func randomIndexes(upTo count: Int, amount: Int) -> [Int] {
    var elements = Array(0..<count)

    var output: [Int] = []

    for _ in 0..<amount {
        let index = Int.random(in: 0..<elements.count)
        let item = elements.remove(at: index)
        output.append(item)
    }

    return output
}

// ugh
private struct NodeIndexesGeneratorMap: AsyncSequence, AsyncIteratorProtocol {
    fileprivate typealias Element = Int
    fileprivate typealias AsyncIterator = Self

    fileprivate func makeAsyncIterator() -> AsyncIterator {
        self
    }

    fileprivate init(indecies: [Int], passthrough: Bool, ctx: ExecuteContext) {
        // `popLast` is generally faster, sooo...
        self.source = indecies.reversed()
        self.passthrough = passthrough
        self.ctx = ctx
    }

    fileprivate var source: [Int]
    fileprivate let passthrough: Bool
    fileprivate let ctx: ExecuteContext

    mutating func next() async -> Int? {
        func recursePing(ctx: ExecuteContext, nodeIndex: Int) async -> Bool {
            let request = PingQuery(nodeAccountId: ctx.network.nodes[nodeIndex])

            let res: ()? = try? await executeAnyInner(
                ctx: ExecuteContext(
                    operatorAccountId: nil,
                    network: ctx.network,
                    backoffConfig: ctx.backoffConfig,
                    maxAttempts: ctx.maxAttempts,
                    grpcTimeout: ctx.grpcTimeout
                ),
                executable: request
            )

            return res != nil

        }

        guard let current = source.popLast() else {
            return nil
        }

        if passthrough {
            return current
        }

        if ctx.network.nodeRecentlyPinged(current, now: .now) {
            return current
        }

        if await recursePing(ctx: ctx, nodeIndex: current) {
            return current
        }

        return nil
    }
}

// this is made complicated by the fact that we *might* have to ping nodes (and we really want to not do that if at all possible)
private func randomNodeIndexes(ctx: ExecuteContext, explicitNodeIndexes: [Int]?) -> NodeIndexesGeneratorMap {
    let nodeIndexes = explicitNodeIndexes ?? ctx.network.healthyNodeIndexes()

    let nodeSampleAmount = (explicitNodeIndexes != nil) ? nodeIndexes.count : (nodeIndexes.count + 2) / 3

    let randomNodeIndexes = randomIndexes(upTo: nodeIndexes.count, amount: nodeSampleAmount).map { nodeIndexes[$0] }

    return NodeIndexesGeneratorMap(indecies: randomNodeIndexes, passthrough: explicitNodeIndexes != nil, ctx: ctx)
}
