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

internal final class FileAppendTransactionTests: XCTestCase {
    private static let fileId = FileId("0.0.10")
    private static let contents = "{foo: 231}".data(using: .utf8)!

    private static func makeTransaction() throws -> FileAppendTransaction {
        try FileAppendTransaction()
            .nodeAccountIds(Resources.nodeAccountIds)
            .transactionId(Resources.txId)
            .maxTransactionFee(Hbar(2))
            .sign(Resources.privateKey)
            .fileId(fileId)
            .contents(contents)
            .freeze()
    }

    internal func testSerialize() throws {
        let tx = try Self.makeTransaction()

        // Unlike most transactions, this iteration makes sure the chunked data is properly handled.
        // NOTE: Without a client, dealing with chunked data is cumbersome.
        let bodyBytes = try tx.makeSources().signedTransactions.makeIterator().map { signed in
            try Proto_TransactionBody.init(serializedBytes: signed.bodyBytes)
        }

        let txes = try bodyBytes.makeIterator().map { bytes in
            try Resources.checkTransactionBody(body: bytes)
        }

        assertSnapshot(of: txes, as: .description)
    }

    internal func testToFromBytes() throws {
        let tx = try Self.makeTransaction()

        let tx2 = try Transaction.fromBytes(try tx.toBytes())

        // As stated above, this assignment properly handles the possibilty of the data being chunked.
        let txBody = try tx.makeSources().signedTransactions.makeIterator().map { signed in
            try Proto_TransactionBody.init(serializedBytes: signed.bodyBytes)
        }

        let txBody2 = try tx2.makeSources().signedTransactions.makeIterator().map { signed in
            try Proto_TransactionBody.init(serializedBytes: signed.bodyBytes)
        }

        XCTAssertEqual(txBody, txBody2)
    }

    internal func testGetSetFileId() throws {
        let tx = FileAppendTransaction.init()
        tx.fileId(Self.fileId)

        XCTAssertEqual(tx.fileId, Self.fileId)
    }

    internal func testGetSetContents() throws {
        let tx = FileAppendTransaction.init()
        tx.contents(Self.contents)

        XCTAssertEqual(tx.contents, Self.contents)
    }
}
