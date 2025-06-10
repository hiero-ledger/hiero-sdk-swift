// SPDX-License-Identifier: Apache-2.0

import GRPC
import HieroProtobufs

/// Get all the information about a schedule.
public final class ScheduleInfoQuery: Query<ScheduleInfo> {
    /// Create a new `ScheduleInfoQuery`.
    public init(
        scheduleId: ScheduleId? = nil
    ) {
        self.scheduleId = scheduleId
    }

    /// The schedule ID for which information is requested.
    public var scheduleId: ScheduleId?

    /// Sets the schedule ID for which information is requested.
    @discardableResult
    public func scheduleId(_ scheduleId: ScheduleId) -> Self {
        self.scheduleId = scheduleId

        return self
    }

    internal override func toQueryProtobufWith(_ header: Proto_QueryHeader) -> Proto_Query {
        .with { proto in
            proto.scheduleGetInfo = .with { proto in
                proto.header = header
                scheduleId?.toProtobufInto(&proto.scheduleID)
            }
        }
    }

    internal override func queryExecute(_ channel: GRPCChannel, _ request: Proto_Query) async throws -> Proto_Response {
        try await Proto_ScheduleServiceAsyncClient(channel: channel).getScheduleInfo(
            request, callOptions: applyGrpcHeader())
    }

    internal override func makeQueryResponse(_ response: Proto_Response.OneOf_Response) throws -> Response {
        guard case .scheduleGetInfo(let proto) = response else {
            throw HError.fromProtobuf("unexpected \(response) received, expected `scheduleGetInfo`")
        }

        return try .fromProtobuf(proto.scheduleInfo)
    }

    internal override func validateChecksums(on ledgerId: LedgerId) throws {
        try scheduleId?.validateChecksums(on: ledgerId)
        try super.validateChecksums(on: ledgerId)
    }
}
