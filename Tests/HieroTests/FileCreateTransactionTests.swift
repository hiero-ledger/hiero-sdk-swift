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

internal final class FileCreateTransactionTests: XCTestCase {
    private static let contents: Data = "[swift::unit::fileCreate::1]".data(using: .utf8)!
    private static let expirationTime = Timestamp(seconds: 1_554_158_728, subSecondNanos: 0)
    private static let keys: KeyList = [.single(Resources.publicKey)]
    private static let fileMemo = "Hello memo"

    private static func createTransaction() throws -> FileCreateTransaction {
        try FileCreateTransaction()
            .nodeAccountIds(Resources.nodeAccountIds)
            .transactionId(Resources.txId)
            .sign(Resources.privateKey)
            .maxTransactionFee(.fromTinybars(100_000))
            .contents(contents)
            .expirationTime(expirationTime)
            .keys(keys)
            .fileMemo(fileMemo)
            .freeze()
    }

    internal func testSerialize() throws {
        let tx = try Self.createTransaction().makeProtoBody()

        assertSnapshot(matching: tx, as: .description)
    }

    internal func testToFromBytes() throws {
        let tx = try Self.createTransaction()
        let tx2 = try Transaction.fromBytes(tx.toBytes())

        XCTAssertEqual(try tx.makeProtoBody(), try tx2.makeProtoBody())
    }

    internal func testFromProtoBody() throws {
        let protoData = Proto_FileCreateTransactionBody.with { proto in
            proto.contents = Self.contents
            proto.expirationTime = Self.expirationTime.toProtobuf()
            proto.keys = Self.keys.toProtobuf()
            proto.memo = Self.fileMemo
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.fileCreate = protoData
            proto.transactionID = Resources.txId.toProtobuf()
        }

        let tx = try FileCreateTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.contents, Self.contents)
        XCTAssertEqual(tx.expirationTime, Self.expirationTime)
        XCTAssertEqual(tx.keys, Self.keys)
        XCTAssertEqual(tx.fileMemo, Self.fileMemo)
    }

    internal func testGetSetContents() {
        let tx = FileCreateTransaction()

        XCTAssertEqual(tx.contents, Data())

        tx.contents(Self.contents)

        XCTAssertEqual(tx.contents, Self.contents)
    }

    internal func testGetSetExpirationTime() {
        let tx = FileCreateTransaction()

        tx.expirationTime(Self.expirationTime)

        XCTAssertEqual(tx.expirationTime, Self.expirationTime)
    }

    internal func testGetSetKeys() {
        let tx = FileCreateTransaction()

        XCTAssertEqual(tx.keys, [])

        tx.keys(Self.keys)

        XCTAssertEqual(tx.keys, Self.keys)
    }

    internal func testGetSetFileMemo() {
        let tx = FileCreateTransaction()

        XCTAssertEqual(tx.fileMemo, "")

        tx.fileMemo(Self.fileMemo)

        XCTAssertEqual(tx.fileMemo, Self.fileMemo)
    }
}
