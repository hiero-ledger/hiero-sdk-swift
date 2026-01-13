// SPDX-License-Identifier: Apache-2.0

import Foundation
import GRPC
import HieroProtobufs
import SwiftProtobuf

/// Change properties for the given topic.
///
/// Any null field is ignored (left unchanged).
///
public final class TopicUpdateTransaction: Transaction {
    /// Create a new `TopicUpdateTransaction` ready for configuration.
    public override init() {
        super.init()
    }

    public init(
        topicId: TopicId? = nil,
        expirationTime: Timestamp? = nil,
        topicMemo: String = "",
        adminKey: Key? = nil,
        submitKey: Key? = nil,
        autoRenewPeriod: Duration? = nil,
        autoRenewAccountId: AccountId? = nil,
        feeScheduleKey: Key? = nil,
        feeExemptKeys: [Key]? = nil,
        customFees: [CustomFixedFee]? = nil
    ) {
        self.topicId = topicId
        self.expirationTime = expirationTime
        self.topicMemo = topicMemo
        self.adminKey = adminKey
        self.submitKey = submitKey
        self.autoRenewPeriod = autoRenewPeriod
        self.autoRenewAccountId = autoRenewAccountId
        self.feeScheduleKey = feeScheduleKey
        self.feeExemptKeys = feeExemptKeys
        self.customFees = customFees

        super.init()
    }

    internal init(protobuf proto: Proto_TransactionBody, _ data: Proto_ConsensusUpdateTopicTransactionBody) throws {
        topicId = data.hasTopicID ? .fromProtobuf(data.topicID) : nil
        expirationTime = data.hasExpirationTime ? .fromProtobuf(data.expirationTime) : nil
        topicMemo = data.hasMemo ? data.memo.value : ""
        adminKey = data.hasAdminKey ? try .fromProtobuf(data.adminKey) : nil
        submitKey = data.hasSubmitKey ? try .fromProtobuf(data.submitKey) : nil
        autoRenewPeriod = data.hasAutoRenewPeriod ? .fromProtobuf(data.autoRenewPeriod) : nil
        autoRenewAccountId = data.hasAutoRenewAccount ? try .fromProtobuf(data.autoRenewAccount) : nil
        feeScheduleKey = data.hasFeeScheduleKey ? try .fromProtobuf(data.feeScheduleKey) : nil
        feeExemptKeys = data.hasFeeExemptKeyList ? try data.feeExemptKeyList.keys.map { try Key.fromProtobuf($0) } : nil
        customFees = data.hasCustomFees ? try data.customFees.fees.map { try CustomFixedFee.fromProtobuf($0) } : nil

        try super.init(protobuf: proto)
    }

    /// The topic ID which is being updated in this transaction.
    public var topicId: TopicId? {
        willSet {
            ensureNotFrozen()
        }
    }

    /// Sets the topic ID which is being updated in this transaction.
    @discardableResult
    public func topicId(_ topicId: TopicId) -> Self {
        self.topicId = topicId

        return self
    }

    /// The new expiration time to extend to (ignored if equal to or before the current one).
    public var expirationTime: Timestamp? {
        willSet {
            ensureNotFrozen()
        }
    }

    /// Sets the new expiration time to extend to (ignored if equal to or before the current one).
    @discardableResult
    public func expirationTime(_ expirationTime: Timestamp) -> Self {
        self.expirationTime = expirationTime

        return self
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

    /// Clears the access control for `TopicUpdateTransaction` and `TopicDeleteTransaction`.
    @discardableResult
    public func clearAdminKey() -> Self {
        self.adminKey = .keyList([])

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

    /// Access control for `TopicMessageSubmitTransaction`.
    @discardableResult
    public func clearSubmitKey() -> Self {
        self.submitKey = .keyList([])

        return self
    }

    /// The initial lifetime of the topic and the amount of time to attempt to
    /// extend the topic's lifetime by automatically at the topic's expiration time, if
    /// the `autoRenewAccountId` is configured.
    public var autoRenewPeriod: Duration? {
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

    /// Clear the auto renew account ID for this topic.
    @discardableResult
    public func clearAutoRenewAccountId() -> Self {
        self.autoRenewAccountId = 0

        return self
    }

    /// Access control for update/delete of custom fees.
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
    /// Set to `nil` to leave unchanged, or `[]` to clear existing keys.
    public var feeExemptKeys: [Key]? {
        willSet {
            ensureNotFrozen()
        }
    }

    /// If the transaction contains a signer from this list, no custom fees are applied.
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
    public func addFeeExemptKey(_ feeExemptKey: Key) -> Self {
        if self.feeExemptKeys == nil {
            self.feeExemptKeys = []
        }
        self.feeExemptKeys!.append(feeExemptKey)

        return self
    }

    /// The custom fixed fee to be assessed during a message submission to this topic.
    /// Set to `nil` to leave unchanged, or `[]` to clear existing fees.
    public var customFees: [CustomFixedFee]? {
        willSet {
            ensureNotFrozen()
        }
    }

    /// Sets the fixed fees for the existing topic.
    @discardableResult
    public func customFees(_ customFees: [CustomFixedFee]) -> Self {
        self.customFees = customFees

        return self
    }

    /// Clears the fixed fees for the existing topic.
    @discardableResult
    public func clearCustomFees() -> Self {
        self.customFees = []

        return self
    }

    /// Appends a fixed fee to the existing topic.
    @discardableResult
    public func addCustomFee(_ customFee: CustomFixedFee) -> Self {
        if self.customFees == nil {
            self.customFees = []
        }
        self.customFees!.append(customFee)

        return self
    }

    internal override func validateChecksums(on ledgerId: LedgerId) throws {
        try topicId?.validateChecksums(on: ledgerId)
        try autoRenewAccountId?.validateChecksums(on: ledgerId)
        try super.validateChecksums(on: ledgerId)
    }

    internal override func transactionExecute(
        _ channel: GRPCChannel, _ request: Proto_Transaction, _ deadline: TimeInterval
    ) async throws
        -> Proto_TransactionResponse
    {
        try await Proto_ConsensusServiceAsyncClient(channel: channel).updateTopic(
            request, callOptions: applyGrpcHeader(deadline: deadline))
    }

    internal override func toTransactionDataProtobuf(_ chunkInfo: ChunkInfo) -> Proto_TransactionBody.OneOf_Data {
        _ = chunkInfo.assertSingleTransaction()

        return .consensusUpdateTopic(toProtobuf())
    }
}

extension TopicUpdateTransaction: ToProtobuf {
    internal typealias Protobuf = Proto_ConsensusUpdateTopicTransactionBody

    internal func toProtobuf() -> Protobuf {
        return .with { proto in
            topicId?.toProtobufInto(&proto.topicID)
            expirationTime?.toProtobufInto(&proto.expirationTime)
            proto.memo = Google_Protobuf_StringValue(topicMemo)
            adminKey?.toProtobufInto(&proto.adminKey)
            submitKey?.toProtobufInto(&proto.submitKey)
            autoRenewPeriod?.toProtobufInto(&proto.autoRenewPeriod)
            autoRenewAccountId?.toProtobufInto(&proto.autoRenewAccount)
            feeScheduleKey?.toProtobufInto(&proto.feeScheduleKey)

            // nil = no change, [] = clear, [...] = update
            if let feeExemptKeys = feeExemptKeys {
                proto.feeExemptKeyList.keys = feeExemptKeys.map { $0.toProtobuf() }
            }

            if let customFees = customFees {
                proto.customFees.fees = customFees.map { $0.toTopicFeeProtobuf() }
            }
        }
    }
}

extension TopicUpdateTransaction {
    internal func toSchedulableTransactionData() -> Proto_SchedulableTransactionBody.OneOf_Data {
        .consensusUpdateTopic(toProtobuf())
    }
}
