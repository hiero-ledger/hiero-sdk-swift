// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class RequestTypeUnitTests: HieroUnitTestCase {
    internal func test_AllCases_ProtobufRoundtrip() throws {
        for original in RequestType.allCases {
            let proto = original.toProtobuf()
            let roundtripped = try RequestType(protobuf: proto)
            XCTAssertEqual(roundtripped, original, "Protobuf roundtrip failed for: \(original)")
        }
    }
}
