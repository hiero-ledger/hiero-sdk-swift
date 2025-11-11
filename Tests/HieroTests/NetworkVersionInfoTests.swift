// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class NetworkVersionInfoTests: XCTestCase {
    private static let info: NetworkVersionInfo = NetworkVersionInfo(protobufVersion: "1.2.3", servicesVersion: "4.5.6")

    internal func testSerialize() {
        assertSnapshot(of: Self.info.toProtobuf(), as: .description)
    }

    internal func testToFromBytes() throws {
        let a = Self.info
        let b = try NetworkVersionInfo.fromBytes(a.toBytes())

        XCTAssertEqual(String(describing: a.protobufVersion), String(describing: b.protobufVersion))
        XCTAssertEqual(String(describing: a.servicesVersion), String(describing: b.servicesVersion))
    }
}
