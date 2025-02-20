import Foundation
import HieroProtobufs

/// Metadata for an individual chunk of a `TopicMessage`.
public struct TopicMessageChunk: Sendable {
    /// The consensus timestamp for this chunk.
    public let consensusTimestamp: Timestamp

    /// How large the content of this specific chunk was.
    public let contentSize: Int

    /// The new running hash of the topic that recieved the message.
    public let runningHash: Data

    /// Sequence number for this chunk.
    public let sequenceNumber: UInt64
}

extension TopicMessageChunk {
    internal init(header: ProtoTopicMessageHeader) {
        self.init(
            consensusTimestamp: header.consensusTimestamp,
            contentSize: header.message.count,
            runningHash: header.runningHash,
            sequenceNumber: header.sequenceNumber
        )
    }
}

/// Topic message records.
public struct TopicMessage: Sendable {
    /// The consensus timestamp of the message.
    ///
    /// If there are multiple chunks, this is taken from the *last* chunk.
    public let consensusTimestamp: Timestamp

    /// The content of the message.
    public let contents: Data

    /// The new running hash of the topic that received the message.
    ///
    /// If there are multiple chunks, this is taken from the *last* chunk.
    public let runningHash: Data

    /// Version of the SHA-384 digest used to update the running hash.
    ///
    /// If there are multiple chunks, this is taken from the *last* chunk.
    public let runningHashVersion: UInt64

    /// The sequence number of the message relative to all other messages
    /// for the same topic.
    ///
    /// If there are multiple chunks, this is taken from the *last* chunk.
    public let sequenceNumber: UInt64

    /// The transaction ID of the first chunk.
    ///
    /// This is shared between every subseqent chunk in a chunked message.
    public let transaction: TransactionId?

    /// The chunks that make up this message.
    public let chunks: [TopicMessageChunk]?
}

extension TopicMessage {
    internal init(single message: ProtoTopicMessageHeader) {
        self.init(
            consensusTimestamp: message.consensusTimestamp,
            contents: message.message,
            runningHash: message.runningHash,
            runningHashVersion: message.runningHashVersion,
            sequenceNumber: message.sequenceNumber,
            transaction: nil,
            chunks: nil
        )
    }

    internal init(chunks: [ProtoTopicMessageChunk]) {
        precondition(chunks.count >= 1, "chunks must not be empty")

        // todo: log stuff (see rust)

        let contents = chunks.reduce(into: Data()) { $0.append($1.header.message) }

        let last = chunks.last!

        let chunks = chunks.map { TopicMessageChunk(header: $0.header) }

        self.init(
            consensusTimestamp: last.header.consensusTimestamp,
            contents: contents,
            runningHash: last.header.runningHash,
            runningHashVersion: last.header.runningHashVersion,
            sequenceNumber: last.header.sequenceNumber,
            transaction: last.initialTransactionId,
            chunks: chunks
        )
    }
}

internal struct ProtoTopicMessageHeader {
    internal let consensusTimestamp: Timestamp
    internal let sequenceNumber: UInt64
    internal let runningHash: Data
    internal let runningHashVersion: UInt64
    internal let message: Data
}

internal struct ProtoTopicMessageChunk {
    internal let header: ProtoTopicMessageHeader
    internal let initialTransactionId: TransactionId
    internal let number: Int32
    internal let total: Int32
}
