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

internal final class TokenIdTests: XCTestCase {
    internal func testFromString() {
        XCTAssertEqual(try TokenId.fromString("0.0.5005"), TokenId(num: 5005))
    }

    internal func testToFromBytes() {
        let a: TokenId = "0.0.5005"
        XCTAssertEqual(a, try TokenId.fromBytes(a.toBytes()))
        let b: TokenId = "1.2.5005"
        XCTAssertEqual(b, try TokenId.fromBytes(b.toBytes()))
    }

    internal func testFromSolidityAddress() {
        assertSnapshot(
            matching: try TokenId.fromSolidityAddress("000000000000000000000000000000000000138d"), as: .description)
    }

    internal func testToSolidityAddress() {
        assertSnapshot(matching: try TokenId(5005).toSolidityAddress(), as: .lines)
    }
}
