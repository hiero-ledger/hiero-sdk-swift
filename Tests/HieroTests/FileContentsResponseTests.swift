// SPDX-License-Identifier: Apache-2.0

import SnapshotTesting
import XCTest

import struct HieroProtobufs.Proto_FileGetContentsResponse

@testable import Hiero

internal final class FileContentsResponseTests: XCTestCase {
    private static let response: Proto_FileGetContentsResponse.FileContents = .with { proto in
        proto.fileID = .with { id in
            id.shardNum = 0
            id.realmNum = 0
            id.fileNum = 5005
        }
        proto.contents = "swift::unit::fileContentResponse::1".data(using: .utf8)!
    }

    internal func testFromProtobuf() throws {
        assertSnapshot(matching: FileContentsResponse.fromProtobuf(Self.response), as: .description)
    }

    internal func testToProtobuf() throws {
        assertSnapshot(matching: FileContentsResponse.fromProtobuf(Self.response).toProtobuf(), as: .description)
    }
}
