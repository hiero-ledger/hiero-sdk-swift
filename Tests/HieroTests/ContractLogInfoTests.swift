// SPDX-License-Identifier: Apache-2.0

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
        assertSnapshot(of: try ContractLogInfo.fromProtobuf(Self.info), as: .description)
    }

    internal func testToProtobuf() throws {
        assertSnapshot(of: try ContractLogInfo.fromProtobuf(Self.info).toProtobuf(), as: .description)
    }

    internal func testFromBytes() throws {
        assertSnapshot(of: try ContractLogInfo.fromBytes(Self.info.serializedData()), as: .description)
    }

    internal func testToBytes() throws {
        assertSnapshot(
            of: try ContractLogInfo.fromBytes(Self.info.serializedData()).toBytes().hexStringEncoded(),
            as: .description)
    }
}
