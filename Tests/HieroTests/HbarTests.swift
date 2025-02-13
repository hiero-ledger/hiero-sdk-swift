/*
 * ‌
 * Hiero Swift SDK
 * ​
 * Copyright (C) 2022 - 2025 Hiero LLC
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

import Foundation
import XCTest

@testable import Hiero

internal final class HbarTests: XCTestCase {
    internal func testInit() throws {
        let fifty: Hbar = 50

        XCTAssertEqual(fifty, Hbar(50))
        XCTAssertEqual(fifty, Hbar(50.0))
        XCTAssertEqual(fifty, 50.0)

        XCTAssertEqual(fifty, "50")
        XCTAssertEqual(fifty, "50.0")
        XCTAssertEqual(fifty, Hbar("50"))
        XCTAssertEqual(fifty, Hbar("50.0"))

        XCTAssertEqual(fifty, try Hbar.from(50))
        XCTAssertEqual(fifty, try Hbar.from(50.0))
        XCTAssertEqual(fifty, try Hbar.fromString("50"))
        XCTAssertEqual(fifty, try Hbar.fromString("50.0"))
        XCTAssertEqual(fifty, Hbar.fromTinybars(5_000_000_000))
    }

    internal func testInitNegative() throws {
        let fifty: Hbar = -50

        XCTAssertEqual(fifty, Hbar(-50))
        XCTAssertEqual(fifty, Hbar(-50.0))
        XCTAssertEqual(fifty, -50.0)

        XCTAssertEqual(fifty, "-50")
        XCTAssertEqual(fifty, "-50.0")
        XCTAssertEqual(fifty, Hbar("-50"))
        XCTAssertEqual(fifty, Hbar("-50.0"))

        XCTAssertEqual(fifty, try Hbar.from(-50))
        XCTAssertEqual(fifty, try Hbar.from(-50.0))
        XCTAssertEqual(fifty, try Hbar.fromString("-50"))
        XCTAssertEqual(fifty, try Hbar.fromString("-50.0"))
        XCTAssertEqual(fifty, Hbar.fromTinybars(-5_000_000_000))
    }

    internal func testFractionalTinybarThrowsError() {
        // todo: test the exact error.
        XCTAssertThrowsError(try Hbar(0.1, .tinybar))
    }

    internal func testNanHbarThrowsError() {
        // todo: test the exact error.
        XCTAssertThrowsError(try Hbar(.quietNaN))
    }

    internal func testInitUnit() throws {
        let fiftyTinybar: Hbar = 0.0000005

        XCTAssertEqual(fiftyTinybar, try Hbar(50, .tinybar))
        XCTAssertEqual(fiftyTinybar, try Hbar(50.0, .tinybar))
        XCTAssertEqual(fiftyTinybar, try Hbar(0.5, .microbar))
        XCTAssertEqual(fiftyTinybar, try Hbar(5e-4, .millibar))
        XCTAssertEqual(fiftyTinybar, try Hbar(5e-7, .hbar))
        XCTAssertEqual(fiftyTinybar, try Hbar(5e-10, .kilobar))
        XCTAssertEqual(fiftyTinybar, "50 tℏ")
        XCTAssertEqual(fiftyTinybar, "50.0 tℏ")
        XCTAssertEqual(fiftyTinybar, "0.5 µℏ")
        XCTAssertEqual(fiftyTinybar, "0.0005 mℏ")
        XCTAssertEqual(fiftyTinybar, "0.0000005 ℏ")
        XCTAssertEqual(fiftyTinybar, "0.0000000005 kℏ")
        XCTAssertEqual(fiftyTinybar, "0.0000000000005 Mℏ")
        XCTAssertEqual(fiftyTinybar, "0.0000000000000005 Gℏ")

        XCTAssertEqual(fiftyTinybar, try Hbar.from(50, .tinybar))
        XCTAssertEqual(fiftyTinybar, try Hbar.from(50.0, .tinybar))
        XCTAssertEqual(fiftyTinybar, try Hbar.from(0.5, .microbar))
        XCTAssertEqual(fiftyTinybar, try Hbar.from(5e-4, .millibar))
        XCTAssertEqual(fiftyTinybar, try Hbar.from(5e-7, .hbar))
        XCTAssertEqual(fiftyTinybar, try Hbar.from(5e-10, .kilobar))
        XCTAssertEqual(fiftyTinybar, try Hbar.fromString("50 tℏ"))
        XCTAssertEqual(fiftyTinybar, try Hbar.fromString("50.0 tℏ"))
        XCTAssertEqual(fiftyTinybar, try Hbar.fromString("0.5 µℏ"))
        XCTAssertEqual(fiftyTinybar, try Hbar.fromString("0.0005 mℏ"))
        XCTAssertEqual(fiftyTinybar, try Hbar.fromString("0.0000005 ℏ"))
        XCTAssertEqual(fiftyTinybar, try Hbar.fromString("0.0000000005 kℏ"))
        XCTAssertEqual(fiftyTinybar, try Hbar.fromString("0.0000000000005 Mℏ"))
        XCTAssertEqual(fiftyTinybar, try Hbar.fromString("0.0000000000000005 Gℏ"))
    }

    internal func testTo() {
        let twentyTwoKilobars: Hbar = 22_000

        XCTAssertEqual(twentyTwoKilobars.value, 22_000)
        XCTAssertEqual(twentyTwoKilobars.to(.tinybar), 2_200_000_000_000)
        XCTAssertEqual(twentyTwoKilobars.to(.microbar), 22_000_000_000)
        XCTAssertEqual(twentyTwoKilobars.to(.millibar), 22_000_000)
        XCTAssertEqual(twentyTwoKilobars.to(.hbar), 22_000)
        XCTAssertEqual(twentyTwoKilobars.to(.kilobar), 22)
        XCTAssertEqual(twentyTwoKilobars.to(.megabar), Decimal(string: "0.022"))
        XCTAssertEqual(twentyTwoKilobars.to(.gigabar), Decimal(string: "0.000022"))
    }

    internal func testNegated() {
        XCTAssertEqual(Hbar(2).negated(), -2)
    }

    // what better way to ensure the right thing gets printed than to test that for all values of <inner range>.
    // it isn't practical to test all ~2^64 values `Hbar` can hold.
    // In fact, this test test's less than 1% of 1% of 1%... of all values.
    internal func testDescription() {
        let innerRange = -9999...9999
        for amount in innerRange {
            let hbar = Hbar.fromTinybars(Int64(amount))
            let expected = "\(amount) tℏ"
            XCTAssertEqual(hbar.toString(), expected)
            XCTAssertEqual(hbar.description, expected)
        }

        for amount in -20000...20_000 where !innerRange.contains(amount) {
            let hbar = Hbar.fromTinybars(Int64(amount))

            let expected = "\(hbar.to(.hbar)) ℏ"
            XCTAssertEqual(hbar.toString(), expected)
            XCTAssertEqual(hbar.description, expected)
        }
    }

    internal func testToStringWithUnit() {
        let fifty: Hbar = 50

        XCTAssertEqual(fifty.toString(.tinybar), "5000000000 tℏ")
        XCTAssertEqual(fifty.toString(.microbar), "50000000 µℏ")
        XCTAssertEqual(fifty.toString(.millibar), "50000 mℏ")
        XCTAssertEqual(fifty.toString(.hbar), "50 ℏ")
        XCTAssertEqual(fifty.toString(.kilobar), "0.05 kℏ")
        XCTAssertEqual(fifty.toString(.megabar), "0.00005 Mℏ")
        XCTAssertEqual(fifty.toString(.gigabar), "0.00000005 Gℏ")
    }

    internal func testToStringWithUnitNegative() {
        let fifty: Hbar = -50

        XCTAssertEqual(fifty.toString(.tinybar), "-5000000000 tℏ")
        XCTAssertEqual(fifty.toString(.microbar), "-50000000 µℏ")
        XCTAssertEqual(fifty.toString(.millibar), "-50000 mℏ")
        XCTAssertEqual(fifty.toString(.hbar), "-50 ℏ")
        XCTAssertEqual(fifty.toString(.kilobar), "-0.05 kℏ")
        XCTAssertEqual(fifty.toString(.megabar), "-0.00005 Mℏ")
        XCTAssertEqual(fifty.toString(.gigabar), "-0.00000005 Gℏ")
    }
}
