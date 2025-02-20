/*
 * ‌
 * Hedera Swift SDK
 * ​
 * Copyright (C) 2023 - 2023 Hedera Hashgraph, LLC
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

internal final class DelegateContractIdTests: XCTestCase {
    internal func testFromString() throws {
        assertSnapshot(matching: try DelegateContractId.fromString("0.0.5005"), as: .description)
    }

    internal func testFromSolidityAddress() throws {
        assertSnapshot(
            matching: try DelegateContractId.fromSolidityAddress("000000000000000000000000000000000000138D"),
            as: .description)
    }

    internal func testFromSolidityAddressWith0x() throws {
        assertSnapshot(
            matching: try DelegateContractId.fromSolidityAddress("0x000000000000000000000000000000000000138D"),
            as: .description)
    }

    internal func testToBytes() throws {
        assertSnapshot(
            matching: try DelegateContractId.fromString("0.0.5005").toBytes().hexStringEncoded(), as: .description)
    }

    internal func testFromBytes() throws {
        assertSnapshot(
            matching: try DelegateContractId.fromBytes(DelegateContractId.fromString("0.0.5005").toBytes()),
            as: .description)
    }

    internal func testToSolidityAddress() throws {
        assertSnapshot(matching: try DelegateContractId(5005).toSolidityAddress(), as: .description)
    }
}
