// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// The unique identifier for a file on Hiero.
public struct FileId: EntityId, ValidateChecksums, Sendable {
    public let shard: UInt64
    public let realm: UInt64
    public let num: UInt64
    public let checksum: Checksum?

    /// Creates a file ID from the given shard, realm, and file numbers.
    ///
    /// - Parameters:
    ///   - shard: the shard in which the file is contained. Defaults to 0.
    ///   - realm: the realm in which the file is contained. Defaults to 0.
    ///   - num: the file number for the file.
    public init(shard: UInt64 = 0, realm: UInt64 = 0, num: UInt64) {
        self.init(shard: shard, realm: realm, num: num, checksum: nil)
    }

    /// Creates a file ID from the given shard, realm, and file numbers, and with the given checksum.
    ///
    /// - Parameters:
    ///   - shard: the shard in which the file is contained.
    ///   - realm: the realm in which the file is contained.
    ///   - num: the file number for the file.
    ///   - checksum: the 5 character checksum of the file.
    public init(shard: UInt64 = 0, realm: UInt64 = 0, num: UInt64, checksum: Checksum?) {
        self.shard = shard
        self.realm = realm
        self.num = num
        self.checksum = checksum
    }

    /// Creates a file ID from the given bytes.
    ///
    /// - Parameters:
    ///   - bytes: the bytes to parse.
    public static func fromBytes(_ bytes: Data) throws -> Self {
        try Self(protobufBytes: bytes)
    }

    /// Converts this file ID to bytes.
    public func toBytes() -> Data {
        toProtobufBytes()
    }

    /// Validates the checksum of this file ID.
    ///
    /// - Parameters:
    ///   - ledgerId: The ledger ID to use to validate the checksum.
    internal func validateChecksums(on ledgerId: LedgerId) throws {
        try helper.validateChecksum(on: ledgerId)
    }

    /// File numbers of static Hiero files.
    fileprivate static let addressBookNum: UInt64 = 102
    fileprivate static let feeScheduleNum: UInt64 = 111
    fileprivate static let exchangeRatesNum: UInt64 = 112

    /// File IDs of static Hiero files.
    public static let addressBook = FileId(num: addressBookNum)
    public static let feeSchedule = FileId(num: feeScheduleNum)
    public static let exchangeRates = FileId(num: exchangeRatesNum)

    /// Get the file ID for the address book for a particular shard and realm.
    ///
    /// - Parameters:
    ///   - shard: the shard of the address book to get.
    ///   - realm: the realm of the address book to get.
    public static func getAddressBookFileIdFor(shard: UInt64 = 0, realm: UInt64 = 0) -> FileId {
        return FileId(shard: shard, realm: realm, num: addressBookNum)
    }

    /// Get the file ID for the fee schedule for a particular shard and realm.
    ///
    /// - Parameters:
    ///   - shard: the shard of the fee schedule to get.
    ///   - realm: the realm of the fee schedule to get.
    public static func getFeeScheduleFileIdFor(shard: UInt64 = 0, realm: UInt64 = 0) -> FileId {
        return FileId(shard: shard, realm: realm, num: feeScheduleNum)
    }

    /// Get the file ID for the exchange rates for a particular shard and realm.
    ///
    /// - Parameters:
    ///   - shard: the shard of the exchange rates to get.
    ///   - realm: the realm of the exchange rates to get.
    public static func getExchangeRatesFileIdFor(shard: UInt64 = 0, realm: UInt64 = 0) -> FileId {
        return FileId(shard: shard, realm: realm, num: exchangeRatesNum)
    }
}

extension FileId: ProtobufCodable {
    internal typealias Protobuf = HieroProtobufs.Proto_FileID

    /// Creates a file ID from a file ID protobuf.
    ///
    /// - Parameters:
    ///   - proto: the file ID protobuf.
    internal init(protobuf proto: Protobuf) {
        self.init(
            shard: UInt64(proto.shardNum),
            realm: UInt64(proto.realmNum),
            num: UInt64(proto.fileNum)
        )
    }

    /// Converts this file ID to a file ID protobuf.
    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.shardNum = Int64(shard)
            proto.realmNum = Int64(realm)
            proto.fileNum = Int64(num)
        }
    }
}
