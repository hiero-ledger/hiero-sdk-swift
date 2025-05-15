// SPDX-License-Identifier: Apache-2.0

import Foundation
import GRPC
import HieroProtobufs
import SwiftProtobuf

public struct PendingAirdropId: Sendable, Equatable {
    /// A sending account.
    ///
    /// This is the account that initiated, and SHALL fund, this pending airdrop.
    /// This field is REQUIRED.
    public let senderId: AccountId

    /// A receiving account.
    ///
    /// This is the ID of the account that SHALL receive the airdrop.
    /// This field is REQUIRED.
    public let receiverId: AccountId

    /// The token to be airdropped.
    public let tokenId: TokenId?

    /// The NFT to be airdropped.
    public let nftId: NftId?

    public init(senderId: AccountId, receiverId: AccountId, tokenId: TokenId) {
        self.senderId = senderId
        self.receiverId = receiverId
        self.tokenId = tokenId
        self.nftId = nil
    }

    public init(senderId: AccountId, receiverId: AccountId, nftId: NftId) {
        self.senderId = senderId
        self.receiverId = receiverId
        self.tokenId = nil
        self.nftId = nftId
    }

    private init(senderId: AccountId, receiverId: AccountId, tokenId: TokenId?, nftId: NftId?) {
        self.senderId = senderId
        self.receiverId = receiverId
        self.tokenId = tokenId
        self.nftId = nftId
    }

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

extension PendingAirdropId: TryProtobufCodable {
    internal typealias Protobuf = Proto_PendingAirdropId

    internal init(protobuf proto: Protobuf) throws {
        var tokenId: TokenId?
        var nftId: NftId?

        if let ref = proto.tokenReference {
            switch ref {
            case .fungibleTokenType(let tokenProto):
                tokenId = TokenId.fromProtobuf(tokenProto)
            case .nonFungibleToken(let nftProto):
                nftId = NftId.fromProtobuf(nftProto)
            }
        }

        self.init(
            senderId: try AccountId(protobuf: proto.senderID),
            receiverId: try AccountId(protobuf: proto.receiverID),
            tokenId: tokenId,
            nftId: nftId
        )
    }

    internal func toProtobuf() -> Protobuf {
        var proto = Protobuf()
        proto.senderID = senderId.toProtobuf()
        proto.receiverID = receiverId.toProtobuf()

        if let tokenId = tokenId {
            proto.tokenReference = .fungibleTokenType(tokenId.toProtobuf())
        } else if let nftId = nftId {
            proto.tokenReference = .nonFungibleToken(nftId.toProtobuf())
        }

        return proto
    }
}
