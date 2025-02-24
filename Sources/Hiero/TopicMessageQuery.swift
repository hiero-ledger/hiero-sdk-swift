import AnyAsyncSequence
import Foundation
import GRPC
import HieroProtobufs

/// Query a stream of Hedera Consensus Service (HCS)
/// messages for an HCS Topic via a specific (possibly open-ended) time range.
public final class TopicMessageQuery: ValidateChecksums, MirrorQuery {
    public typealias Item = TopicMessage
    public typealias Response = [TopicMessage]

    /// Create a new `TopicMessageQuery`.
    public init(
        topicId: TopicId? = nil,
        startTime: Timestamp? = nil,
        endTime: Timestamp? = nil,
        limit: UInt64 = 0
    ) {
        self.topicId = topicId
        self.startTime = startTime
        self.endTime = endTime
        self.limit = limit
    }

    /// The topic ID to retrieve messages for.
    public var topicId: TopicId?

    /// Include messages which reached consensus on or after this time.
    /// Defaults to the current time.
    public var startTime: Timestamp?

    /// Include messages which reached consensus before this time.
    public var endTime: Timestamp?

    /// The maximum number of message to receive before stopping.
    public var limit: UInt64

    /// Sets topic ID to retrieve messages for.
    @discardableResult
    public func topicId(_ topicId: TopicId) -> Self {
        self.topicId = topicId

        return self
    }

    /// Set to include messages which reached consensus on or after this time.
    /// Defaults to the current time.
    @discardableResult
    public func startTime(_ startTime: Timestamp) -> Self {
        self.startTime = startTime

        return self
    }

    /// Set to include messages which reached consensus before this time.
    @discardableResult
    public func endTime(_ endTime: Timestamp) -> Self {
        self.endTime = endTime

        return self
    }

    /// Sets the maximum number of messages to be returned, before closing the subscription.
    /// Defaults to _unlimited_.
    @discardableResult
    public func limit(_ limit: UInt64) -> Self {
        self.limit = limit

        return self
    }

    internal func validateChecksums(on ledgerId: LedgerId) throws {
        try topicId?.validateChecksums(on: ledgerId)
    }

    public func subscribe(_ client: Client, _ timeout: TimeInterval? = nil) -> AnyAsyncSequence<TopicMessage> {
        subscribeInner(client, timeout)
    }

    public func execute(_ client: Client, _ timeout: TimeInterval? = nil) async throws -> [TopicMessage] {
        try await executeInner(client, timeout)
    }
}

extension TopicMessageQuery {
    internal typealias GrpcItem = Com_Hedera_Mirror_Api_Proto_ConsensusTopicResponse

    internal struct Context: MirrorRequestContext {
        internal init(startTime: Timestamp? = nil) {
            self.startTime = startTime
        }

        internal init() {
            self.init(startTime: nil)
        }

        internal let startTime: Timestamp?

        internal mutating func update(item: GrpcItem) {
            let newStartTime = item.hasConsensusTimestamp ? Timestamp(protobuf: item.consensusTimestamp) : nil
            self = Self(startTime: newStartTime ?? startTime)
        }
    }

    private static func mapStream<S>(_ stream: S) -> ItemStream where S: AsyncSequence, GrpcItem == S.Element {
        var incompleteMessages: [TransactionId: IncompleteMessage] = [:]
        return stream.compactMap { item throws -> Item? in
            guard item.hasConsensusTimestamp else {
                throw HError.fromProtobuf("unexpected missing `TopicMessage.consensusTimestamp`")
            }

            let header = ProtoTopicMessageHeader(
                consensusTimestamp: .init(protobuf: item.consensusTimestamp),
                sequenceNumber: item.sequenceNumber,
                runningHash: item.runningHash,
                runningHashVersion: item.runningHashVersion,
                message: item.message
            )

            guard item.hasChunkInfo, item.chunkInfo.total > 1 else {
                return Item(single: header)
            }

            // note: there's a potential DOS if someone sets other fields but no initial transaction ID.
            guard item.chunkInfo.hasInitialTransactionID else {
                throw HError.fromProtobuf("unexpected missing `chunkInfo.initialTransactionid`")
            }

            let messageChunk = ProtoTopicMessageChunk(
                header: header,
                initialTransactionId: try .init(protobuf: item.chunkInfo.initialTransactionID),
                number: item.chunkInfo.number,
                total: item.chunkInfo.total
            )

            let transactionId = messageChunk.initialTransactionId

            var entry = incompleteMessages[transactionId, default: .partial(expiry: .now + .minutes(15), messages: [])]

            entry.handleExpiry()

            guard case .partial(let expiry, var messages) = entry else {
                return nil
            }

            // If we have a duplicate `number`, we'll just ignore it (this is unspecified behavior)
            if !messages.contains(where: { $0.number == messageChunk.number }) {
                messages.append(messageChunk)
            }

            // Find the smallest `total` so that we aren't susceptable to stuff like total changing (and getting bigger)
            // later on there's a check that ensures that they all have the same total.
            let total = messages.lazy.map { $0.total }.min()!

            if messages.count < total {
                incompleteMessages[transactionId] = .partial(expiry: expiry, messages: messages)
                return nil
            }

            incompleteMessages[transactionId] = .complete

            messages.sort(by: { $0.number < $1.number })

            return .init(chunks: messages)
        }.eraseToAnyAsyncSequence()
    }
}

extension TopicMessageQuery: MirrorRequest {
    internal static func collect<S>(_ stream: S) async throws -> Response
    where S: AsyncSequence, GrpcItem == S.Element {
        var items: [Item] = []

        for try await item in Self.mapStream(stream) {
            items.append(item)
        }

        return items
    }

    internal static func makeItemStream<S>(_ stream: S) -> ItemStream where S: AsyncSequence, GrpcItem == S.Element {
        Self.mapStream(stream)
    }

    internal func connect(context: Context, channel: any GRPCChannel) -> ConnectStream {
        let request = Com_Hedera_Mirror_Api_Proto_ConsensusTopicQuery.with { proto in
            topicId?.toProtobufInto(&proto.topicID)

            let startTime = context.startTime?.adding(nanos: 1) ?? self.startTime

            startTime?.toProtobufInto(&proto.consensusStartTime)
            endTime?.toProtobufInto(&proto.consensusEndTime)
            proto.limit = limit
        }

        return HieroProtobufs.Com_Hedera_Mirror_Api_Proto_ConsensusServiceAsyncClient(channel: channel)
            .subscribeTopic(request)
    }
}

private enum IncompleteMessage {
    case partial(expiry: Timestamp, messages: [ProtoTopicMessageChunk])
    case expired
    case complete

    mutating func handleExpiry() {
        if case .partial(let expiry, _) = self, expiry < .now {
            self = .expired
        }
    }
}

// private struct MessagesMapSequence<S>: AsyncSequence where S: AsyncSequence, S.Element == TopicMessageQuery.GrpcItem {
//    typealias Element = TopicMessageQuery.Item
//    let inner: S

//    struct AsyncIterator {
//        let map: [TransactionId: ]
//        let inner: S.AsyncIterator
//    }
// }
