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

internal final class TransactionIdTests: XCTestCase {
    internal func testFromStringWrongField() {
        XCTAssertNil(TransactionId.init("0.0.31415?1641088801.2"))
    }

    internal func testFromStringWrongField2() {
        XCTAssertNil(TransactionId.init("0.0.31415/1641088801.2"))
    }

    internal func testFromStringOutOfOrder() {
        XCTAssertNil(TransactionId.init("0.0.31415?scheduled/1412@1641088801.2"))
    }

    internal func testFromStringSingleDigitNanos() throws {
        let validStart = Timestamp(fromUnixTimestampNanos: 1_641_088_801 * 1_000_000_000 + 2)

        let expected: TransactionId = TransactionId(
            accountId: "0.0.31415",
            validStart: validStart
        )

        XCTAssertEqual("0.0.31415@1641088801.2", expected)
    }

    internal func testToStringSingleDigitNanos() throws {
        let validStart = Timestamp(fromUnixTimestampNanos: 1_641_088_801 * 1_000_000_000 + 2)

        let transactionId: TransactionId = TransactionId(
            accountId: "0.0.31415",
            validStart: validStart
        )

        XCTAssertEqual(transactionId.description, "0.0.31415@1641088801.2")
    }

    internal func testSerialize() {
        assertSnapshot(matching: try TransactionId.fromString("0.0.23847@1588539964.632521325"), as: .description)
    }

    internal func testSerialize2() {
        assertSnapshot(
            matching: try TransactionId.fromString("0.0.23847@1588539964.632521325?scheduled/3"), as: .description)
    }

    internal func testToFromPb() {
        let a: TransactionId = "0.0.23847@1588539964.632521325"

        XCTAssertEqual(a, try TransactionId.fromProtobuf(a.toProtobuf()))
    }

    internal func testToFromPb2() {
        let a: TransactionId = "0.0.23847@1588539964.632521325?scheduled/2"

        XCTAssertEqual(a, try TransactionId.fromProtobuf(a.toProtobuf()))
    }

    internal func testToFromBytes() {
        let a: TransactionId = "0.0.23847@1588539964.632521325"

        XCTAssertEqual(a, try TransactionId.fromBytes(a.toBytes()))
    }

    internal func testParse() throws {
        XCTAssertEqual(
            try TransactionId.fromString("0.0.23847@1588539964.632521325"),
            TransactionId(accountId: 23847, validStart: .init(fromUnixTimestampNanos: 1_588_539_964_632_521_325))
        )
    }

    internal func testParseScheduled() {
        XCTAssertEqual(
            try TransactionId.fromString("0.0.23847@1588539964.632521325?scheduled"),
            TransactionId(
                accountId: 23847,
                validStart: .init(fromUnixTimestampNanos: 1_588_539_964_632_521_325),
                scheduled: true
            )
        )
    }

    internal func testParseNonce() {
        XCTAssertEqual(
            try TransactionId.fromString("0.0.23847@1588539964.632521325/4"),
            TransactionId(
                accountId: 23847,
                validStart: .init(fromUnixTimestampNanos: 1_588_539_964_632_521_325),
                nonce: 4
            )
        )
    }
}
