/*
 * ‌
 * Hedera Swift SDK
 * ​
 * Copyright (C) 2022 - 2024 Hedera Hashgraph, LLC
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

/// Response from `TokenNftInfoQuery`.
public struct TokenNftInfo {
    /// The ID of the NFT.
    public let nftId: NftId

    /// The current owner of the NFT.
    public let accountId: AccountId

    /// Effective consensus timestamp at which the NFT was minted.
    public let creationTime: Timestamp

    /// The unique metadata of the NFT.
    public let metadata: Data

    /// If an allowance is granted for the NFT, its corresponding spender account.
    public let spenderId: AccountId?

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

extension TokenNftInfo: TryProtobufCodable {
    internal typealias Protobuf = Proto_TokenNftInfo

    internal init(protobuf proto: Protobuf) throws {
        let spenderId = proto.hasSpenderID ? proto.spenderID : nil

        self.init(
            nftId: .fromProtobuf(proto.nftID),
            accountId: try .fromProtobuf(proto.accountID),
            creationTime: .fromProtobuf(proto.creationTime),
            metadata: proto.metadata,
            spenderId: try .fromProtobuf(spenderId),
            ledgerId: LedgerId(proto.ledgerID)
        )
    }

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.nftID = nftId.toProtobuf()
            proto.accountID = accountId.toProtobuf()
            proto.creationTime = creationTime.toProtobuf()
            proto.metadata = metadata
            proto.ledgerID = ledgerId.bytes

            if let spenderId = spenderId?.toProtobuf() {
                proto.spenderID = spenderId
            }
        }
    }
}
