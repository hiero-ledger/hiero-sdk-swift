// SPDX-License-Identifier: Apache-2.0

import AnyAsyncSequence
import Foundation
import GRPC
import HieroProtobufs

internal protocol MirrorRequestContext {
    associatedtype GrpcItem
    /// Initialize the context with default values.
    init()

    mutating func update(item: GrpcItem)
}

internal protocol MirrorRequest {
    associatedtype GrpcItem: Sendable
    associatedtype Item
    associatedtype Response
    associatedtype Context: MirrorRequestContext & Sendable where Context.GrpcItem == GrpcItem

    func connect(context: Context, channel: any GRPCChannel) -> ConnectStream

    func shouldRetry(forStatus status: GRPCStatus.Code) -> Bool

    static func makeItemStream<S: AsyncSequence>(_ stream: S) -> ItemStream where S.Element == GrpcItem

    static func collect<S: AsyncSequence>(_ stream: S) async throws -> Response where S.Element == GrpcItem
}

extension MirrorRequest {
    internal typealias ConnectStream = GRPCAsyncResponseStream<GrpcItem>
    internal typealias ItemStream = AnyAsyncSequence<Item>

    internal func shouldRetry(forStatus status: GRPCStatus.Code) -> Bool {
        false
    }
}

/// A query that can be executed against a mirror node.
///
/// This protocol is semantically *sealed* and is not to be implemented by downstream consumers.
public protocol MirrorQuery {
    /// Type of element returned by ``subscribe(_:_:)``.
    associatedtype Item

    /// Type of response from ``execute(_:_:)``
    associatedtype Response

    /// Execute this mirror query in a streaming fashion.
    ///
    /// - Returns: some async sequence of ``Item``.
    func subscribe(_ client: Client, _ timeout: TimeInterval?) -> AnyAsyncSequence<Item>

    /// Execute this mirror query and collect all the items.
    ///
    /// - Returns: The ``Response`` from executing the mirror query.
    func execute(_ client: Client, _ timeout: TimeInterval?) async throws -> Response
}

// Due to access level requirements,
// these functions can't be put right on `MirrorQuery` without making `MirrorRequest` public
// And we don't want mirror request to be public.
extension MirrorQuery where Self: MirrorRequest & ValidateChecksums {
    /// Execute this mirror query in a streaming fashion.
    ///
    /// - Returns: some async sequence of ``Item``.
    internal func subscribeInner(_ client: Client, _ timeout: TimeInterval? = nil) -> ItemStream {
        // default timeout of 15 minutes.
        let timeout = timeout ?? TimeInterval(900)

        // todo: validating checksums is hard because uh we can't error here, which means we'd need to check in the `MirrorQuerySubscribeIterator`.
        // if client.isAutoValidateChecksumsEnabled() {
        //     try validateChecksums(on: client)
        // }

        return Self.makeItemStream(mirrorSubscribe(client.mirrorChannel, self, timeout))
    }

    /// Execute this mirror query and collect all the items.
    ///
    /// - Returns: The ``Response`` from executing the mirror query.
    internal func executeInner(_ client: Client, _ timeout: TimeInterval? = nil) async throws -> Response {
        if client.isAutoValidateChecksumsEnabled() {
            try validateChecksums(on: client)
        }

        return try await executeChannel(client.mirrorChannel, timeout)
    }

    internal func executeChannel(_ channel: any GRPCChannel, _ timeout: TimeInterval? = nil) async throws -> Response {
        // default timeout of 15 minutes.
        let timeout = timeout ?? TimeInterval(900)

        return try await Self.collect(mirrorSubscribe(channel, self, timeout))
    }
}

private struct MirrorQuerySubscribeIterator<R: MirrorRequest>: AsyncIteratorProtocol {
    fileprivate init(
        request: R,
        channel: GRPCChannel,
        timeout: TimeInterval
    ) {
        self.request = request
        self.channel = channel
        self.state = .start
        self.backoff = ExponentialBackoff(maxElapsedTime: .limited(timeout))
        self.backoffInfinity = ExponentialBackoff(maxElapsedTime: .unlimited)
        self.context = .init()
    }

    private let request: R
    private let channel: GRPCChannel
    private var state: State
    private var backoff: ExponentialBackoff
    private var backoffInfinity: ExponentialBackoff
    private var context: R.Context

    enum State {
        case start
        case running(stream: R.ConnectStream.AsyncIterator)
        case finished
    }

    // state machine, weeeeeeee
    // basically:
    //  `.start` -> connect (enter `.running`)
    // `.running` -> yield item until error or `nil`
    // on error:
    //  if retry is applicable:
    //    await backoff
    //    enter .start
    // else: yield error, enter `.finished`
    // on nil: enter `.finished`, yield `nil`
    // `.finished` -> return `nil`
    mutating func next() async throws -> R.GrpcItem? {
        while true {
            try Task.checkCancellation()
            switch state {
            case .start:
                state = .running(
                    stream: request.connect(context: context, channel: channel).makeAsyncIterator()
                )

                backoff.reset()
                backoffInfinity.reset()

            case .running(var stream):
                do {
                    guard let result = try await stream.next() else {
                        state = .finished
                        return nil
                    }

                    context.update(item: result)

                    return result
                } catch let error as GRPCStatus {
                    switch error.code {
                    case .unavailable, .resourceExhausted, .aborted:
                        state = .start
                        let timeout = backoffInfinity.next()!
                        try await Task.sleep(nanoseconds: timeout.nanoseconds)

                    case let code where request.shouldRetry(forStatus: code):
                        state = .start
                        guard let timeout = backoff.next() else {
                            throw HError.timedOut(
                                String(
                                    describing: HError(
                                        kind: .grpcStatus(status: Int32(code.rawValue)),
                                        description: error.description
                                    )))
                        }

                        try await Task.sleep(nanoseconds: timeout.nanoseconds)

                    case let code:
                        state = .finished
                        throw HError(
                            kind: .grpcStatus(status: Int32(code.rawValue)),
                            description: error.description
                        )
                    }
                } catch {
                    state = .finished
                    throw error
                }
            case .finished:
                return nil
            }
        }
    }

    fileprivate typealias Element = R.GrpcItem
}

private struct MirrorSubscribeStream<R: MirrorRequest>: AsyncSequence {
    typealias AsyncIterator = MirrorQuerySubscribeIterator<R>
    typealias Element = R.GrpcItem

    let request: R
    let channel: GRPCChannel
    let timeout: TimeInterval

    func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(
            request: request,
            channel: channel,
            timeout: timeout
        )
    }
}

private func mirrorSubscribe<R: MirrorRequest>(_ channel: GRPCChannel, _ request: R, _ timeout: TimeInterval)
    -> AnyAsyncSequence<R.GrpcItem>
{
    MirrorSubscribeStream(request: request, channel: channel, timeout: timeout).eraseToAnyAsyncSequence()
}
