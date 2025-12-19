// SPDX-License-Identifier: Apache-2.0

import Foundation
import GRPC
import HieroProtobufs

/// Retrieve the latest state of a topic.
public final class TopicInfoQuery: Query<TopicInfo> {
    /// Create a new `TopicInfoQuery`.
    public init(
        topicId: TopicId? = nil
    ) {
        self.topicId = topicId
    }

    /// The topic ID for which information is requested.
    public var topicId: TopicId?

    /// Sets the topic ID for which information is requested.
    @discardableResult
    public func topicId(_ topicId: TopicId) -> Self {
        self.topicId = topicId

        return self
    }

    internal override func toQueryProtobufWith(_ header: Proto_QueryHeader) -> Proto_Query {
        .with { proto in
            proto.consensusGetTopicInfo = .with { proto in
                proto.header = header
                topicId?.toProtobufInto(&proto.topicID)
            }
        }
    }

    internal override func queryExecute(_ channel: GRPCChannel, _ request: Proto_Query, _ deadline: TimeInterval)
        async throws -> Proto_Response
    {
        try await Proto_ConsensusServiceAsyncClient(channel: channel).getTopicInfo(
            request, callOptions: applyGrpcHeader(deadline: deadline))
    }

    internal override func makeQueryResponse(_ response: Proto_Response.OneOf_Response) throws -> Response {
        guard case .consensusGetTopicInfo(let proto) = response else {
            throw HError.fromProtobuf("unexpected \(response) received, expected `consensusGetTopicInfo`")
        }

        return try .fromProtobuf(proto)
    }

    internal override func validateChecksums(on ledgerId: LedgerId) throws {
        try topicId?.validateChecksums(on: ledgerId)
        try super.validateChecksums(on: ledgerId)
    }
}
