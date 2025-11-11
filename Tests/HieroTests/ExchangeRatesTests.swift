// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class ExchangeRatesTests: XCTestCase {
    internal func testFromProtobuf() throws {
        let exchangeRates = try ExchangeRates.fromBytes(
            Data(hexEncoded: "0a1008b0ea0110b6b4231a0608f0bade9006121008b0ea01108cef231a060880d7de9006")!
        )

        assertSnapshot(of: exchangeRates, as: .description)
    }
}
