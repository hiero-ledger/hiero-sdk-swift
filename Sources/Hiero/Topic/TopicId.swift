// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// The unique identifier for a topic on Hiero.
public struct TopicId: EntityId, ValidateChecksums, Sendable {
    public let shard: UInt64
    public let realm: UInt64
    public let num: UInt64
    public let checksum: Checksum?

    /// Creates a topic ID from the given shard, realm, and topic numbers.
    ///
    /// - Parameters:
    ///   - shard: the shard in which the topic is contained. Defaults to 0.
    ///   - realm: the realm in which the topic is contained. Defaults to 0.
    ///   - num: the topic number for the topic.
    public init(shard: UInt64 = 0, realm: UInt64 = 0, num: UInt64) {
        self.init(shard: shard, realm: realm, num: num, checksum: nil)
    }

    /// Creates a topic ID from the given shard, realm, and topic numbers, and with the given checksum.
    ///
    /// - Parameters:
    ///   - shard: the shard in which the topic is contained.
    ///   - realm: the realm in which the topic is contained.
    ///   - num: the topic number for the topic.
    ///   - checksum: the 5 character checksum of the topic.
    public init(shard: UInt64 = 0, realm: UInt64 = 0, num: UInt64, checksum: Checksum?) {
        self.shard = shard
        self.realm = realm
        self.num = num
        self.checksum = checksum
    }

    /// Creates a topic ID from the given bytes.
    ///
    /// - Parameters:
    ///   - bytes: the bytes to parse.
    public static func fromBytes(_ bytes: Data) throws -> Self {
        try Self(protobufBytes: bytes)
    }

    /// Converts this topic ID to bytes.
    public func toBytes() -> Data {
        toProtobufBytes()
    }

    /// Validates the checksum of this topic ID.
    ///
    /// - Parameters:
    ///   - ledgerId: The ledger ID to use to validate the checksum.
    internal func validateChecksums(on ledgerId: LedgerId) throws {
        try helper.validateChecksum(on: ledgerId)
    }
}

extension TopicId: ProtobufCodable {
    internal typealias Protobuf = HieroProtobufs.Proto_TopicID

    /// Creates a topic ID from a topic ID protobuf.
    ///
    /// - Parameters:
    ///   - proto: the topic ID protobuf.
    internal init(protobuf proto: Protobuf) {
        self.init(
            shard: UInt64(proto.shardNum),
            realm: UInt64(proto.realmNum),
            num: UInt64(proto.topicNum)
        )
    }

    /// Converts this topic ID to a topic ID protobuf.
    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.shardNum = Int64(shard)
            proto.realmNum = Int64(realm)
            proto.topicNum = Int64(num)
        }
    }
}
