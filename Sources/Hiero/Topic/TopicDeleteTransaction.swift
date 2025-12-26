// SPDX-License-Identifier: Apache-2.0

import Foundation
import GRPC
import HieroProtobufs

/// Delete a topic.
///
/// No more transactions or queries on the topic will succeed.
///
/// If an `admin_key` is set, this transaction must be signed by that key.
/// If there is no `admin_key`, this transaction will fail `UNAUTHORIZED`.
///
public final class TopicDeleteTransaction: Transaction {
    /// Create a new `TopicDeleteTransaction` ready for configuration.
    public override init() {
        super.init()
    }

    internal init(protobuf proto: Proto_TransactionBody, _ data: Proto_ConsensusDeleteTopicTransactionBody) throws {
        self.topicId = data.hasTopicID ? .fromProtobuf(data.topicID) : nil

        try super.init(protobuf: proto)
    }

    /// The topic ID which is being deleted in this transaction.
    public var topicId: TopicId? {
        willSet {
            ensureNotFrozen()
        }
    }

    /// Sets the topic ID which is being deleted in this transaction.
    @discardableResult
    public func topicId(_ topicId: TopicId) -> Self {
        self.topicId = topicId

        return self
    }

    internal override func validateChecksums(on ledgerId: LedgerId) throws {
        try topicId?.validateChecksums(on: ledgerId)
        try super.validateChecksums(on: ledgerId)
    }

    internal override func transactionExecute(
        _ channel: GRPCChannel, _ request: Proto_Transaction, _ deadline: TimeInterval
    ) async throws
        -> Proto_TransactionResponse
    {
        try await Proto_ConsensusServiceAsyncClient(channel: channel).deleteTopic(
            request, callOptions: applyGrpcHeader(deadline: deadline))
    }

    internal override func toTransactionDataProtobuf(_ chunkInfo: ChunkInfo) -> Proto_TransactionBody.OneOf_Data {
        _ = chunkInfo.assertSingleTransaction()

        return .consensusDeleteTopic(toProtobuf())
    }
}

extension TopicDeleteTransaction: ToProtobuf {
    internal typealias Protobuf = Proto_ConsensusDeleteTopicTransactionBody

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            topicId?.toProtobufInto(&proto.topicID)
        }
    }
}

extension TopicDeleteTransaction {
    internal func toSchedulableTransactionData() -> Proto_SchedulableTransactionBody.OneOf_Data {
        .consensusDeleteTopic(toProtobuf())
    }
}
