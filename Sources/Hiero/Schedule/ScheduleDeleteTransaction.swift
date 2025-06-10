// SPDX-License-Identifier: Apache-2.0

import GRPC
import HieroProtobufs

/// Marks a schedule in the network's action queue as deleted.
public final class ScheduleDeleteTransaction: Transaction {
    /// Create a new `ScheduleDeleteTransaction`.
    public init(
        scheduleId: ScheduleId? = nil
    ) {
        self.scheduleId = scheduleId
        super.init()
    }

    internal init(protobuf proto: Proto_TransactionBody, _ data: Proto_ScheduleDeleteTransactionBody) throws {
        scheduleId = data.hasScheduleID ? .fromProtobuf(data.scheduleID) : nil

        try super.init(protobuf: proto)
    }

    /// The schedule to delete.
    public var scheduleId: ScheduleId? {
        willSet {
            ensureNotFrozen(fieldName: "scheduleId")
        }
    }

    /// Sets the schedule to delete.
    @discardableResult
    public func scheduleId(_ scheduleId: ScheduleId) -> Self {
        self.scheduleId = scheduleId

        return self
    }

    internal override func validateChecksums(on ledgerId: LedgerId) throws {
        try scheduleId?.validateChecksums(on: ledgerId)
        try super.validateChecksums(on: ledgerId)
    }

    internal override func transactionExecute(_ channel: GRPCChannel, _ request: Proto_Transaction) async throws
        -> Proto_TransactionResponse
    {
        try await Proto_ScheduleServiceAsyncClient(channel: channel).deleteSchedule(
            request, callOptions: applyGrpcHeader())
    }

    internal override func toTransactionDataProtobuf(_ chunkInfo: ChunkInfo) -> Proto_TransactionBody.OneOf_Data {
        _ = chunkInfo.assertSingleTransaction()

        return .scheduleDelete(toProtobuf())
    }
}

extension ScheduleDeleteTransaction: ToProtobuf {
    internal typealias Protobuf = Proto_ScheduleDeleteTransactionBody

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            scheduleId?.toProtobufInto(&proto.scheduleID)
        }
    }
}

extension ScheduleDeleteTransaction {
    internal func toSchedulableTransactionData() -> Proto_SchedulableTransactionBody.OneOf_Data {
        .scheduleDelete(toProtobuf())
    }
}
