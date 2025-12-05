// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class LedgerIdUnitTests: HieroUnitTestCase {
    internal func test_ToString() throws {
        XCTAssertEqual(LedgerId.mainnet.toString(), "mainnet")
        XCTAssertEqual(LedgerId.testnet.toString(), "testnet")
        XCTAssertEqual(LedgerId.previewnet.toString(), "previewnet")
        XCTAssertEqual(LedgerId.fromBytes(Data([0x00, 0xFF, 0x00, 0xFF])), "00FF00FF")
    }

    internal func test_FromString() throws {
        XCTAssertEqual(LedgerId.fromString("mainnet"), LedgerId.mainnet)
        XCTAssertEqual(LedgerId.fromString("testnet"), LedgerId.testnet)
        XCTAssertEqual(LedgerId.fromString("previewnet"), LedgerId.previewnet)
        XCTAssertEqual(LedgerId.fromString("00ff00ff"), LedgerId.fromBytes(Data([0x00, 0xFF, 0x00, 0xFF])))
        XCTAssertEqual(LedgerId.fromString("00FF00FF"), LedgerId.fromBytes(Data([0x00, 0xFF, 0x00, 0xFF])))
    }

    internal func test_ToBytes() throws {
        let bytes = Data([0x00, 0xFF, 0x00, 0xFF])
        XCTAssertEqual(LedgerId.fromBytes(Data([0x00, 0xFF, 0x00, 0xFF])).bytes, bytes)
    }
}
