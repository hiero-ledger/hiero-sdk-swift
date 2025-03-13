// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs

/// Information about a single account that is proxy staking.
public struct ProxyStaker {
    /// The Account ID that is proxy staking.
    public let accountId: AccountId

    /// The number of hbars that are currently proxy staked.
    public let amount: UInt64
}

extension ProxyStaker: TryProtobufCodable {
    internal typealias Protobuf = Proto_ProxyStaker

    internal init(protobuf proto: Protobuf) throws {
        self.init(accountId: try .fromProtobuf(proto.accountID), amount: UInt64(proto.amount))
    }

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.accountID = accountId.toProtobuf()
            proto.amount = Int64(amount)
        }
    }
}
