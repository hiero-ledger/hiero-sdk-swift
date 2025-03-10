// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// Info related to account/contract staking settings.
public struct StakingInfo: Sendable {
    /// If true, the contract declines receiving a staking reward. The default value is false.
    public let declineStakingReward: Bool

    /// The staking period during which either the staking settings for this account or contract changed
    /// (such as starting staking or changing staked_node_id)
    /// or the most recent reward was earned, whichever is later.
    /// If this account or contract is not currently staked to a node, then this field is not set.
    public let stakePeriodStart: Timestamp?

    /// The amount in Hbar that will be received in the next reward situation.
    public let pendingReward: Hbar

    /// The total of balance of all accounts staked to this account or contract.
    public let stakedToMe: Hbar

    /// The account to which this account or contract is staking.
    public let stakedAccountId: AccountId?

    /// The ID of the node this account or contract is staked to.
    public let stakedNodeId: UInt64?

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

extension StakingInfo: TryProtobufCodable {
    internal typealias Protobuf = Proto_StakingInfo

    internal init(protobuf proto: Protobuf) throws {
        let stakePeriodStart = proto.hasStakePeriodStart ? proto.stakePeriodStart : nil
        let stakedAccountId: Proto_AccountID?
        let stakedNodeId: UInt64?
        switch proto.stakedID {
        case .stakedNodeID(let nodeId):
            stakedAccountId = nil
            stakedNodeId = UInt64(nodeId)
        case .stakedAccountID(let accountId):
            stakedAccountId = accountId
            stakedNodeId = nil
        case nil:
            stakedAccountId = nil
            stakedNodeId = nil
        }

        self.init(
            declineStakingReward: proto.declineReward,
            stakePeriodStart: .fromProtobuf(stakePeriodStart),
            pendingReward: .fromTinybars(proto.pendingReward),
            stakedToMe: .fromTinybars(proto.stakedToMe),
            stakedAccountId: try .fromProtobuf(stakedAccountId),
            stakedNodeId: stakedNodeId
        )
    }

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.declineReward = declineStakingReward
            stakePeriodStart?.toProtobufInto(&proto.stakePeriodStart)
            proto.pendingReward = pendingReward.toTinybars()
            proto.stakedToMe = stakedToMe.toTinybars()

            stakedAccountId?.toProtobufInto(&proto.stakedAccountID)

            // node ID wins, so it goes last.
            if let nodeId = stakedNodeId {
                proto.stakedNodeID = Int64(nodeId)
            }
        }
    }
}
