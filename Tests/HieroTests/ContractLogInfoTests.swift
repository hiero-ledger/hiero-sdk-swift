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

import struct HieroProtobufs.Proto_ContractLoginfo

@testable import Hiero

internal final class ContractLogInfoTests: XCTestCase {
    private static let info: Proto_ContractLoginfo = .with { proto in
        proto.contractID = .with { id in
            id.shardNum = 0
            id.realmNum = 0
            id.contractNum = 10
        }
        proto.bloom = "bloom".data(using: .utf8)!
        proto.topic = ["topic".data(using: .utf8)!]
        proto.data = "data".data(using: .utf8)!
    }

    internal func testFromProtobuf() throws {
        assertSnapshot(matching: try ContractLogInfo.fromProtobuf(Self.info), as: .description)
    }

    internal func testToProtobuf() throws {
        assertSnapshot(matching: try ContractLogInfo.fromProtobuf(Self.info).toProtobuf(), as: .description)
    }

    internal func testFromBytes() throws {
        assertSnapshot(matching: try ContractLogInfo.fromBytes(Self.info.serializedData()), as: .description)
    }

    internal func testToBytes() throws {
        assertSnapshot(
            matching: try ContractLogInfo.fromBytes(Self.info.serializedData()).toBytes().hexStringEncoded(),
            as: .description)
    }
}
