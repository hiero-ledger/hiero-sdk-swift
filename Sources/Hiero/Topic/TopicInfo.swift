// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// Response from `TopicInfoQuery`.
public struct TopicInfo {
    /// The ID of the topic for which information is requested.
    public let topicId: TopicId

    /// Short publicly visible memo about the topic. No guarantee of uniqueness
    public let topicMemo: String

    /// SHA-384 running hash of (previousRunningHash, topicId, consensusTimestamp, sequenceNumber, message).
    public let runningHash: Data

    /// Sequence number (starting at 1 for the first submitMessage) of messages on the topic.
    public let sequenceNumber: UInt64

    /// Effective consensus timestamp at (and after) which submitMessage calls will no longer succeed on the topic.
    public let expirationTime: Timestamp?

    /// Access control for update/delete of the topic.
    public let adminKey: Key?

    /// Access control for submit message.
    public let submitKey: Key?

    /// An account which will be automatically charged to renew the topic's expiration, at
    /// `auto_renew_period` interval.
    public let autoRenewAccountId: AccountId?

    /// The interval at which the auto-renew account will be charged to extend the topic's expiry.
    public let autoRenewPeriod: Duration?

    /// The ledger ID the response was returned from
    public let ledgerId: LedgerId

    /// Decode `Self` from protobuf-encoded `bytes`.
    ///
    /// - Throws: ``HError/ErrorKind/fromProtobuf`` if:
    ///           decoding the bytes fails to produce a valid protobuf, or
    ///            decoding the protobuf fails.
    public static func fromBytes(_ bytes: Data) throws -> Self {
        try Self(protobufBytes: bytes)
    }

    /// Convert `self` to protobuf encoded data.
    public func toBytes() -> Data {
        toProtobufBytes()
    }
}

extension TopicInfo: TryProtobufCodable {
    internal typealias Protobuf = Proto_ConsensusGetTopicInfoResponse

    internal init(protobuf proto: Protobuf) throws {
        let info = proto.topicInfo

        let expirationTime = info.hasExpirationTime ? info.expirationTime : nil
        let adminKey = info.hasAdminKey ? info.adminKey : nil
        let submitKey = info.hasSubmitKey ? info.submitKey : nil
        let autoRenewAccountId = info.hasAutoRenewAccount ? info.autoRenewAccount : nil
        let autoRenewPeriod = info.hasAutoRenewPeriod ? info.autoRenewPeriod : nil

        self.init(
            topicId: .fromProtobuf(proto.topicID),
            topicMemo: info.memo,
            runningHash: info.runningHash,
            sequenceNumber: info.sequenceNumber,
            expirationTime: .fromProtobuf(expirationTime),
            adminKey: try .fromProtobuf(adminKey),
            submitKey: try .fromProtobuf(submitKey),
            autoRenewAccountId: try .fromProtobuf(autoRenewAccountId),
            autoRenewPeriod: .fromProtobuf(autoRenewPeriod),
            ledgerId: LedgerId(info.ledgerID)
        )
    }

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.topicID = topicId.toProtobuf()

            proto.topicInfo = .with { info in
                info.memo = topicMemo

                info.runningHash = runningHash
                info.sequenceNumber = sequenceNumber

                if let expirationTime = expirationTime {
                    info.expirationTime = expirationTime.toProtobuf()
                }

                if let adminKey = adminKey {
                    info.adminKey = adminKey.toProtobuf()
                }

                if let submitKey = submitKey {
                    info.submitKey = submitKey.toProtobuf()
                }

                if let autoRenewAccountId = autoRenewAccountId {
                    info.autoRenewAccount = autoRenewAccountId.toProtobuf()
                }
                if let autoRenewPeriod = autoRenewPeriod {
                    info.autoRenewPeriod = autoRenewPeriod.toProtobuf()
                }

                info.ledgerID = ledgerId.bytes
            }
        }
    }
}
