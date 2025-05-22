// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// The unique identifier for a file on Hiero.
public struct FileId: EntityId, ValidateChecksums, Sendable {
    public init(shard: UInt64 = 0, realm: UInt64 = 0, num: UInt64, checksum: Checksum?) {
        self.shard = shard
        self.realm = realm
        self.num = num
        self.checksum = checksum
    }

    public init(shard: UInt64 = 0, realm: UInt64 = 0, num: UInt64) {
        self.init(shard: shard, realm: realm, num: num, checksum: nil)
    }

    public let shard: UInt64
    public let realm: UInt64

    /// The file number.
    public let num: UInt64

    public let checksum: Checksum?

    fileprivate static let addressBookNum: UInt64 = 102
    fileprivate static let feeScheduleNum: UInt64 = 111
    fileprivate static let exchangeRatesNum: UInt64 = 112

    public static let addressBook = FileId(num: addressBookNum)
    public static let feeSchedule = FileId(num: feeScheduleNum)
    public static let exchangeRates = FileId(num: exchangeRatesNum)

    public static func getAddressBookFileIdFor(shard: UInt64 = 0, realm: UInt64 = 0) -> FileId {
        return FileId(shard: shard, realm: realm, num: addressBookNum)
    }

    public static func getFeeScheduleFileIdFor(shard: UInt64 = 0, realm: UInt64 = 0) -> FileId {
        return FileId(shard: shard, realm: realm, num: feeScheduleNum)
    }

    public static func getExchangeRatesFileIdFor(shard: UInt64 = 0, realm: UInt64 = 0) -> FileId {
        return FileId(shard: shard, realm: realm, num: exchangeRatesNum)
    }

    public static func fromBytes(_ bytes: Data) throws -> Self {
        try Self(protobufBytes: bytes)
    }

    public func toBytes() -> Data {
        toProtobufBytes()
    }

    internal func validateChecksums(on ledgerId: LedgerId) throws {
        try helper.validateChecksum(on: ledgerId)
    }
}

extension FileId: ProtobufCodable {
    internal typealias Protobuf = HieroProtobufs.Proto_FileID

    internal init(protobuf proto: Protobuf) {
        self.init(
            shard: UInt64(proto.shardNum),
            realm: UInt64(proto.realmNum),
            num: UInt64(proto.fileNum)
        )
    }

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.shardNum = Int64(shard)
            proto.realmNum = Int64(realm)
            proto.fileNum = Int64(num)
        }
    }
}
