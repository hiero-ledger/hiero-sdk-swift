// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class FileContentsQueryTests: XCTestCase {
    internal func testSerialize() throws {
        let query = try FileContentsQuery()
            .fileId(FileId.fromString("0.0.5005"))
            .toQueryProtobufWith(.init())

        assertSnapshot(of: query, as: .description)
    }

    internal func testGetSetFileId() throws {
        let query = FileContentsQuery()
        query.fileId(Resources.fileId)

        XCTAssertEqual(query.fileId, Resources.fileId)
    }
}
