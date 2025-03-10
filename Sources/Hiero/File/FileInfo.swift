// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// Response from `FileInfoQuery`.
public struct FileInfo {
    /// The file ID of the file for which information is requested.
    public let fileId: FileId

    /// Number of bytes in contents.
    public let size: UInt64

    /// Current time which this account is set to expire.
    public let expirationTime: Timestamp?

    /// True if deleted but not yet expired.
    public let isDeleted: Bool

    /// One of these keys must sign in order to modify or delete the file.
    public let keys: KeyList

    /// Memo associated with the file.
    public let fileMemo: String

    /// Ledger ID for the network the response was returned from.
    public let ledgerId: LedgerId

    /// The auto renew period for this file.
    ///
    /// > Warning: This not supported on any hedera network at this time.
    public let autoRenewPeriod: Duration?

    /// The account to be used at this file's expiration time to extend the
    /// life of the file.
    ///
    /// > Warning: This not supported on any hedera network at this time.
    public let autoRenewAccountId: AccountId?

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

extension FileInfo: TryProtobufCodable {
    internal typealias Protobuf = Proto_FileGetInfoResponse.FileInfo

    internal init(protobuf proto: Protobuf) throws {
        let expirationTime = proto.hasExpirationTime ? proto.expirationTime : nil
        self.init(
            fileId: .fromProtobuf(proto.fileID),
            size: UInt64(proto.size),
            expirationTime: .fromProtobuf(expirationTime),
            isDeleted: proto.deleted,
            keys: try .fromProtobuf(proto.keys),
            fileMemo: proto.memo,
            ledgerId: LedgerId(proto.ledgerID),
            autoRenewPeriod: nil,
            autoRenewAccountId: nil
        )
    }

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.fileID = fileId.toProtobuf()
            proto.size = Int64(bitPattern: size)

            if let expirationTime = expirationTime?.toProtobuf() {
                proto.expirationTime = expirationTime
            }

            proto.deleted = isDeleted
            proto.memo = fileMemo
            proto.keys = keys.toProtobuf()
            proto.ledgerID = ledgerId.bytes
        }
    }
}
