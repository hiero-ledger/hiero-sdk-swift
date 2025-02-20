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

internal final class FileIdTests: XCTestCase {
    internal func testFromString() {
        XCTAssertEqual(try FileId.fromString("0.0.5005"), FileId(num: 5005))
    }

    internal func testToFromBytes() {
        let a: FileId = "0.0.5005"
        XCTAssertEqual(a, try FileId.fromBytes(a.toBytes()))
        let b: FileId = "1.2.5005"
        XCTAssertEqual(b, try FileId.fromBytes(b.toBytes()))
    }

    internal func testFromSolidarityAddress() {
        assertSnapshot(
            matching: try FileId.fromSolidityAddress("000000000000000000000000000000000000138D"), as: .description)
    }

    internal func testToSolidityAddress() {
        assertSnapshot(matching: try FileId(5005).toSolidityAddress(), as: .lines)
    }
}
