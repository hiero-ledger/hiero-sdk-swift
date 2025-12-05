// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class FileContentsQueryUnitTests: HieroUnitTestCase, QueryTestable {
    static func makeQueryProto() throws -> Proto_Query {
        try FileContentsQuery()
            .fileId(FileId.fromString("0.0.5005"))
            .toQueryProtobufWith(.init())
    }

    internal func test_Serialize() throws {
        try assertQuerySerializes()
    }

    internal func test_GetSetFileId() throws {
        let query = FileContentsQuery()
        query.fileId(TestConstants.fileId)

        XCTAssertEqual(query.fileId, TestConstants.fileId)
    }
}
