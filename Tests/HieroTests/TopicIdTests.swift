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

import SnapshotTesting
import XCTest

@testable import Hiero

internal final class TopicIdTests: XCTestCase {
    internal func testParse() {
        assertSnapshot(matching: try TopicId.fromString("0.0.5005"), as: .description)
    }

    internal func testFromSolidityAddress() {
        assertSnapshot(
            matching: try TopicId.fromSolidityAddress("000000000000000000000000000000000000138D"),
            as: .description
        )
    }

    internal func testFromSolidityAddress0x() {
        assertSnapshot(
            matching: try TopicId.fromSolidityAddress("0x000000000000000000000000000000000000138D"),
            as: .description
        )
    }

    internal func testToFromBytes() {
        let a: TopicId = "1.2.3"
        XCTAssertEqual(a, try .fromBytes(a.toBytes()))
    }

    internal func testToSolidityAddress() {
        assertSnapshot(matching: try TopicId(num: 5005).toSolidityAddress(), as: .lines)
    }
}
