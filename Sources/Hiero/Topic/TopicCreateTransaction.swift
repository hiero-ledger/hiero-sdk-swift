// SPDX-License-Identifier: Apache-2.0

import Foundation
import GRPC
import HieroProtobufs

/// Create a topic to be used for consensus.
///
/// If an `autoRenewAccountId` is specified, that account must also sign this transaction.
///
/// If an `adminKey` is specified, the adminKey must sign the transaction.
///
/// On success, the resulting `TransactionReceipt` contains the newly created `TopicId`.
public final class TopicCreateTransaction: Transaction {
    /// Create a new `TopicCreateTransaction` ready for configuration.
    public override init() {
        super.init()
    }

    internal init(protobuf proto: Proto_TransactionBody, _ data: Proto_ConsensusCreateTopicTransactionBody) throws {
        topicMemo = data.memo
        adminKey = data.hasAdminKey ? try .fromProtobuf(data.adminKey) : nil
        submitKey = data.hasSubmitKey ? try .fromProtobuf(data.submitKey) : nil
        autoRenewPeriod = data.hasAutoRenewPeriod ? .fromProtobuf(data.autoRenewPeriod) : nil
        autoRenewAccountId = data.hasAutoRenewAccount ? try .fromProtobuf(data.autoRenewAccount) : nil
        feeScheduleKey = data.hasFeeScheduleKey ? try .fromProtobuf(data.feeScheduleKey) : nil
        feeExemptKeys = try data.feeExemptKeyList.map { try .fromProtobuf($0) }
        customFees = try data.customFees.map { try .fromProtobuf($0) }

        try super.init(protobuf: proto)
    }

    @discardableResult
    public override func freezeWith(_ client: Client?) throws -> Self {
        if self.autoRenewAccountId == nil {
            if let feePayerAccountId = transactionId?.accountId {
                self.autoRenewAccountId = feePayerAccountId
            } else if let client = client, let clientOperatorAccountId = client.operator?.accountId {
                self.autoRenewAccountId = clientOperatorAccountId
            }
        }

        return try super.freezeWith(client)
    }

    /// Short publicly visible memo about the topic. No guarantee of uniqueness.
    public var topicMemo: String = "" {
        willSet {
            ensureNotFrozen()
        }
    }

    /// Sets the short publicly visible memo about the topic.
    @discardableResult
    public func topicMemo(_ topicMemo: String) -> Self {
        self.topicMemo = topicMemo

        return self
    }

    /// Access control for `TopicUpdateTransaction` and `TopicDeleteTransaction`.
    public var adminKey: Key? {
        willSet {
            ensureNotFrozen()
        }
    }

    /// Sets the access control for `TopicUpdateTransaction` and `TopicDeleteTransaction`.
    @discardableResult
    public func adminKey(_ adminKey: Key) -> Self {
        self.adminKey = adminKey

        return self
    }

    /// Access control for `TopicMessageSubmitTransaction`.
    public var submitKey: Key? {
        willSet {
            ensureNotFrozen()
        }
    }

    /// Sets the access control for `TopicMessageSubmitTransaction`.
    @discardableResult
    public func submitKey(_ submitKey: Key) -> Self {
        self.submitKey = submitKey

        return self
    }

    /// The initial lifetime of the topic and the amount of time to attempt to
    /// extend the topic's lifetime by automatically at the topic's expiration time, if
    /// the `autoRenewAccountId` is configured.
    public var autoRenewPeriod: Duration? = .days(90) {
        willSet {
            ensureNotFrozen()
        }
    }

    /// Sets the initial lifetime of the topic and the amount of time to attempt to
    /// extend the topic's lifetime by automatically at the topic's expiration time.
    @discardableResult
    public func autoRenewPeriod(_ autoRenewPeriod: Duration) -> Self {
        self.autoRenewPeriod = autoRenewPeriod

        return self
    }

    /// Account to be used at the topic's expiration time to extend the life of the topic.
    public var autoRenewAccountId: AccountId? {
        willSet {
            ensureNotFrozen()
        }
    }

    /// Sets the account to be used at the topic's expiration time to extend the life of the topic.
    @discardableResult
    public func autoRenewAccountId(_ autoRenewAccountId: AccountId) -> Self {
        self.autoRenewAccountId = autoRenewAccountId

        return self
    }

    /// The key that can be used to update the fee schedule for the topic.
    public var feeScheduleKey: Key? {
        willSet {
            ensureNotFrozen()
        }
    }

    /// Sets the key that can be used to update the fee schedule for the topic.
    @discardableResult
    public func feeScheduleKey(_ feeScheduleKey: Key) -> Self {
        self.feeScheduleKey = feeScheduleKey

        return self
    }

    /// The keys that can be used to update the fee schedule for the topic.
    public var feeExemptKeys: [Key] = [] {
        willSet {
            ensureNotFrozen()
        }
    }

    /// Sets the keys that can be used to update the fee schedule for the topic.
    @discardableResult
    public func feeExemptKeys(_ feeExemptKeys: [Key]) -> Self {
        self.feeExemptKeys = feeExemptKeys

        return self
    }

    /// Clears all keys that will be exempt from paying fees.
    @discardableResult
    public func clearFeeExemptKeys() -> Self {
        self.feeExemptKeys = []

        return self
    }

    /// Adds a key that will be exempt from paying fees.
    @discardableResult
    public func addFeeExemptKeys(_ feeExemptKey: Key) -> Self {
        self.feeExemptKeys.append(feeExemptKey)

        return self
    }

    /// The custom fees that will be applied to the topic.
    public var customFees: [CustomFixedFee] = [] {
        willSet {
            ensureNotFrozen()
        }
    }

    /// Sets the custom fees that will be applied to the topic.
    @discardableResult
    public func customFees(_ customFees: [CustomFixedFee]) -> Self {
        self.customFees = customFees

        return self
    }

    /// Clears the custom fees that will be applied to the topic.
    @discardableResult
    public func clearCustomFees() -> Self {
        self.customFees = []

        return self
    }

    /// Adds a custom fee that will be applied to the topic.
    @discardableResult
    public func addCustomFee(_ customFee: CustomFixedFee) -> Self {
        self.customFees.append(customFee)

        return self
    }

    internal override func validateChecksums(on ledgerId: LedgerId) throws {
        try autoRenewAccountId?.validateChecksums(on: ledgerId)
        try super.validateChecksums(on: ledgerId)
    }

    internal override func transactionExecute(
        _ channel: GRPCChannel, _ request: Proto_Transaction, _ deadline: TimeInterval
    ) async throws
        -> Proto_TransactionResponse
    {
        try await Proto_ConsensusServiceAsyncClient(channel: channel).createTopic(
            request, callOptions: applyGrpcHeader(deadline: deadline))
    }

    internal override func toTransactionDataProtobuf(_ chunkInfo: ChunkInfo) -> Proto_TransactionBody.OneOf_Data {
        _ = chunkInfo.assertSingleTransaction()

        return .consensusCreateTopic(toProtobuf())
    }
}

extension TopicCreateTransaction: ToProtobuf {
    internal typealias Protobuf = Proto_ConsensusCreateTopicTransactionBody

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.memo = topicMemo
            adminKey?.toProtobufInto(&proto.adminKey)
            submitKey?.toProtobufInto(&proto.submitKey)
            autoRenewPeriod?.toProtobufInto(&proto.autoRenewPeriod)
            autoRenewAccountId?.toProtobufInto(&proto.autoRenewAccount)
            if let feeScheduleKey = feeScheduleKey {
                proto.feeScheduleKey = feeScheduleKey.toProtobuf()
            }

            if !feeExemptKeys.isEmpty {
                proto.feeExemptKeyList = feeExemptKeys.map { $0.toProtobuf() }
            }

            if !customFees.isEmpty {
                proto.customFees = customFees.map { $0.toTopicFeeProtobuf() }
            }
        }
    }
}

extension TopicCreateTransaction {
    internal func toSchedulableTransactionData() -> Proto_SchedulableTransactionBody.OneOf_Data {
        .consensusCreateTopic(toProtobuf())
    }
}
