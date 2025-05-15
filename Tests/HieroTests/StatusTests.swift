// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import XCTest

@testable import Hiero

internal final class StatusTests: XCTestCase {
    internal func testToResponseCode() {
        for code in Proto_ResponseCodeEnum.allCases {
            if code == Proto_ResponseCodeEnum.UNRECOGNIZED(-1) {
                continue
            }

            let status = Status.init(rawValue: Int32(code.rawValue))

            XCTAssertEqual(code.rawValue, Int(status.rawValue))
        }
    }
}
