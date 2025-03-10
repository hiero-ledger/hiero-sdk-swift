// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// A token <-> account association.
public struct TokenAssociation: Sendable {
    /// The token involved in the association.
    public let tokenId: TokenId

    /// The account involved in the association.
    public let accountId: AccountId

    public static func fromBytes(_ bytes: Data) throws -> Self {
        try Self(protobufBytes: bytes)
    }

    /// Convert self to protobuf encoded bytes.
    public func toBytes() -> Data {
        toProtobufBytes()
    }
}

extension TokenAssociation: TryProtobufCodable {
    internal typealias Protobuf = Proto_TokenAssociation

    internal init(protobuf proto: Protobuf) throws {
        tokenId = .fromProtobuf(proto.tokenID)
        accountId = try .fromProtobuf(proto.accountID)
    }

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.tokenID = tokenId.toProtobuf()
            proto.accountID = accountId.toProtobuf()
        }
    }
}
