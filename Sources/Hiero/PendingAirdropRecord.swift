/*
 * ‌
 * Hedera Swift SDK
 * ​
 * Copyright (C) 2023 - 2023 Hedera Hashgraph, LLC
 * ​
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ‍
 */

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
