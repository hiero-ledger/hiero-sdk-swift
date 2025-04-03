// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// A record of a new pending airdrop.
public struct PendingAirdropRecord {
    /// The pending airdrop ID.
    public let pendingAirdropId: PendingAirdropId
    /// The amount to be airdropped.
    public let amount: UInt64
}

extension PendingAirdropRecord: TryProtobufCodable {
    internal typealias Protobuf = Proto_PendingAirdropRecord

    internal init(protobuf proto: Protobuf) throws {
        self.pendingAirdropId = try PendingAirdropId(protobuf: proto.pendingAirdropID)
        self.amount = proto.pendingAirdropValue.amount
    }

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.pendingAirdropID = pendingAirdropId.toProtobuf()
            proto.pendingAirdropValue.amount = amount
        }
    }
}

#if compiler(<5.7)
    // Swift 5.7 added the conformance to data, despite to the best of my knowledge, not changing anything in the underlying type.
    extension PendingAirdropRecord: @unchecked Sendable {}
#else
    extension PendingAirdropRecord: Sendable {}
#endif
