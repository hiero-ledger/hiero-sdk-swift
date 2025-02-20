import SnapshotTesting
import XCTest

import struct HieroProtobufs.Proto_ContractNonceInfo

@testable import Hiero

internal class ContractNonceInfoTests: XCTestCase {
    private static let info: Proto_ContractNonceInfo = .with { proto in
        proto.contractID = .with { contract in
            contract.shardNum = 0
            contract.realmNum = 0
            contract.contractNum = 2
        }
        proto.nonce = 2
    }

    internal func testFromProtobuf() {
        assertSnapshot(matching: try ContractNonceInfo.fromProtobuf(Self.info), as: .description)
    }

    internal func testToProtobuf() throws {
        assertSnapshot(matching: try ContractNonceInfo.fromProtobuf(Self.info).toProtobuf(), as: .description)
    }

    internal func testFromBytes() throws {
        assertSnapshot(
            matching: try ContractNonceInfo.fromBytes(Self.info.serializedData()).toProtobuf(), as: .description)
    }
}
