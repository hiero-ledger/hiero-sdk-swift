// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// The unique identifier for a token on Hiero.
public struct TokenId: EntityId, ValidateChecksums, Sendable, Equatable, Comparable {
    public let shard: UInt64
    public let realm: UInt64
    public let num: UInt64
    public let checksum: Checksum?

    /// Creates a token ID from the given shard, realm, and token numbers.
    ///
    /// - Parameters:
    ///   - shard: the shard in which the token is contained. Defaults to 0.
    ///   - realm: the realm in which the token is contained. Defaults to 0.
    ///   - num: the token number for the token.
    public init(shard: UInt64 = 0, realm: UInt64 = 0, num: UInt64) {
        self.init(shard: shard, realm: realm, num: num, checksum: nil)
    }

    /// Creates a token ID from the given shard, realm, and token numbers, and with the given checksum.
    ///
    /// - Parameters:
    ///   - shard: the shard in which the token is contained.
    ///   - realm: the realm in which the token is contained.
    ///   - num: the token number for the token.
    ///   - checksum: the 5 character checksum of the token.
    public init(shard: UInt64 = 0, realm: UInt64 = 0, num: UInt64, checksum: Checksum?) {
        self.shard = shard
        self.realm = realm
        self.num = num
        self.checksum = checksum
    }

    /// Creates a token ID from the given bytes.
    ///
    /// - Parameters:
    ///   - bytes: the bytes to parse.
    public static func fromBytes(_ bytes: Data) throws -> Self {
        try Self(protobufBytes: bytes)
    }

    /// Converts this token ID to bytes.
    public func toBytes() -> Data {
        toProtobufBytes()
    }

    /// Validates the checksum of this token ID.
    ///
    /// - Parameters:
    ///   - ledgerId: The ledger ID to use to validate the checksum.
    internal func validateChecksums(on ledgerId: LedgerId) throws {
        try helper.validateChecksum(on: ledgerId)
    }

    /// Creates an NFT ID based on this token and a serial number.
    ///
    /// - Parameters:
    ///   - serial: the serial number of the NFT.
    public func nft(_ serial: UInt64) -> NftId {
        NftId(tokenId: self, serial: serial)
    }

    /// Is a token ID "less" than another?
    ///
    /// - Parameters:
    ///   - lhs: the left hand side token ID.
    ///   - rhs: the right hand side token ID.
    public static func < (lhs: TokenId, rhs: TokenId) -> Bool {
        if lhs.shard != rhs.shard {
            return lhs.shard < rhs.shard
        }
        if lhs.realm != rhs.realm {
            return lhs.realm < rhs.realm
        }
        return lhs.num < rhs.num
    }
}

extension TokenId: ProtobufCodable {
    internal typealias Protobuf = HieroProtobufs.Proto_TokenID

    /// Creates a token ID from a token ID protobuf.
    ///
    /// - Parameters:
    ///   - proto: the token ID protobuf.
    internal init(protobuf proto: Protobuf) {
        self.init(
            shard: UInt64(proto.shardNum),
            realm: UInt64(proto.realmNum),
            num: UInt64(proto.tokenNum)
        )
    }

    /// Converts this token ID to a token ID protobuf.
    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.shardNum = Int64(shard)
            proto.realmNum = Int64(realm)
            proto.tokenNum = Int64(num)
        }
    }
}
