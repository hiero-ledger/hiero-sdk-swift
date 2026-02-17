// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class FeeDataTypeUnitTests: HieroUnitTestCase {
    internal func test_AllCases_ProtobufRoundtrip() throws {
        for original in FeeDataType.allCases {
            let proto = original.toProtobuf()
            let roundtripped = try FeeDataType(protobuf: proto)
            XCTAssertEqual(roundtripped, original, "Protobuf roundtrip failed for: \(original)")
        }
    }
}
