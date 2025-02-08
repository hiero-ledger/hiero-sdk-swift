// SPDX-License-Identifier: Apache-2.0

import SnapshotTesting
import XCTest

@testable import Hiero

internal final class FileInfoQueryTests: XCTestCase {
    internal func testSerialize() throws {
        let query = try FileInfoQuery()
            .fileId(FileId.fromString("0.0.5005"))
            .toQueryProtobufWith(.init())

        assertSnapshot(matching: query, as: .description)
    }

    internal func testGetSetFileId() throws {
        let query = FileInfoQuery()
        query.fileId(Resources.fileId)

        XCTAssertEqual(query.fileId, Resources.fileId)
    }
}
