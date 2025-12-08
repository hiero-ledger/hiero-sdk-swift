// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import SnapshotTesting
import XCTest

import struct HieroProtobufs.Proto_FileGetContentsResponse

@testable import Hiero

internal final class FileContentsResponseUnitTests: HieroUnitTestCase {
    private static let response: Proto_FileGetContentsResponse.FileContents = .with { proto in
        proto.fileID = .with { id in
            id.shardNum = 0
            id.realmNum = 0
            id.fileNum = 5005
        }
        proto.contents = "swift::unit::fileContentResponse::1".data(using: .utf8)!
    }

    internal func test_FromProtobuf() throws {
        SnapshotTesting.assertSnapshot(of: FileContentsResponse.fromProtobuf(Self.response), as: .description)
    }

    internal func test_ToProtobuf() throws {
        SnapshotTesting.assertSnapshot(
            of: FileContentsResponse.fromProtobuf(Self.response).toProtobuf(), as: .description)
    }
}
