// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class StatusUnitTests: HieroUnitTestCase {
    internal func test_ToResponseCode() {
        for code in Proto_ResponseCodeEnum.allCases {
            if code == Proto_ResponseCodeEnum.UNRECOGNIZED(-1) {
                continue
            }

            let status = Status.init(rawValue: Int32(code.rawValue))

            XCTAssertEqual(code.rawValue, Int(status.rawValue))
        }
    }
}
