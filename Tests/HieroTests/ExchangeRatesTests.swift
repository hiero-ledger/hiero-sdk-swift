/*
 * ‌
 * Hedera Swift SDK
 * ​
 * Copyright (C) 2022 - 2024 Hedera Hashgraph, LLC
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

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class ExchangeRatesTests: XCTestCase {
    internal func testFromProtobuf() throws {
        let exchangeRates = try ExchangeRates.fromBytes(
            Data(hexEncoded: "0a1008b0ea0110b6b4231a0608f0bade9006121008b0ea01108cef231a060880d7de9006")!
        )

        assertSnapshot(matching: exchangeRates, as: .description)
    }
}
