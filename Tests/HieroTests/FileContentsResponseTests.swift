/*
 * ‌
 * Hedera Swift SDK
 * ​
 * Copyright (C) 2023 - 2023 Hedera Hashgraph, LLC
 * ​
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ‍
 */

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
