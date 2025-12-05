// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import SnapshotTesting
import XCTest

import struct HieroProtobufs.Proto_FileGetInfoResponse
import struct HieroProtobufs.Proto_Key

@testable import Hiero

internal final class FileInfoUnitTests: HieroUnitTestCase {
    private static let info: Proto_FileGetInfoResponse.FileInfo = .with { proto in
        proto.fileID = FileId(num: 1).toProtobuf()
        proto.size = 2
        proto.expirationTime = .with { proto in
            proto.seconds = 1_554_158_728
        }
        proto.deleted = true
        proto.keys = .with { proto in
            proto.keys = [TestConstants.publicKey.toProtobuf()]
        }
        proto.ledgerID = LedgerId.testnet.bytes
        proto.memo = "flook"
    }

    internal func test_FromProtobuf() throws {
        SnapshotTesting.assertSnapshot(of: try FileInfo.fromProtobuf(Self.info), as: .description)
    }

    internal func test_ToProtobuf() throws {
        SnapshotTesting.assertSnapshot(of: try FileInfo.fromProtobuf(Self.info).toProtobuf(), as: .description)
    }

    internal func test_FromBytes() throws {
        SnapshotTesting.assertSnapshot(of: try FileInfo.fromBytes(Self.info.serializedData()), as: .description)
    }

    internal func test_ToBytes() throws {
        SnapshotTesting.assertSnapshot(
            of: try FileInfo.fromBytes(Self.info.serializedData()).toBytes().hexStringEncoded(), as: .description)
    }
}
