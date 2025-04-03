// SPDX-License-Identifier: Apache-2.0

import SnapshotTesting
import XCTest

import struct HieroProtobufs.Proto_FileGetInfoResponse
import struct HieroProtobufs.Proto_Key

@testable import Hiero

internal final class FileInfoTests: XCTestCase {
    private static let info: Proto_FileGetInfoResponse.FileInfo = .with { proto in
        proto.fileID = FileId(num: 1).toProtobuf()
        proto.size = 2
        proto.expirationTime = .with { proto in
            proto.seconds = 1_554_158_728
        }
        proto.deleted = true
        proto.keys = .with { proto in
            proto.keys = [Resources.publicKey.toProtobuf()]
        }
        proto.ledgerID = LedgerId.testnet.bytes
        proto.memo = "flook"
    }

    internal func testFromProtobuf() throws {
        assertSnapshot(matching: try FileInfo.fromProtobuf(Self.info), as: .description)
    }

    internal func testToProtobuf() throws {
        assertSnapshot(matching: try FileInfo.fromProtobuf(Self.info).toProtobuf(), as: .description)
    }

    internal func testFromBytes() throws {
        assertSnapshot(matching: try FileInfo.fromBytes(Self.info.serializedData()), as: .description)
    }

    internal func testToBytes() throws {
        assertSnapshot(
            matching: try FileInfo.fromBytes(Self.info.serializedData()).toBytes().hexStringEncoded(), as: .description)
    }
}
