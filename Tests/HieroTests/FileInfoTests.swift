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
