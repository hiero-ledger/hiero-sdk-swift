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

internal final class FileDeleteTransactionTests: XCTestCase {
    private static func makeTransaction() throws -> FileDeleteTransaction {
        try FileDeleteTransaction()
            .nodeAccountIds(Resources.nodeAccountIds)
            .transactionId(Resources.txId)
            .sign(Resources.privateKey)
            .fileId("0.0.6006")
            .maxTransactionFee(.fromTinybars(100_000))
            .freeze()
    }

    internal func testSerialize() throws {
        let tx = try Self.makeTransaction().makeProtoBody()

        assertSnapshot(matching: tx, as: .description)
    }

    internal func testToFromBytes() throws {
        let tx = try Self.makeTransaction()
        let tx2 = try Transaction.fromBytes(tx.toBytes())

        XCTAssertEqual(try tx.makeProtoBody(), try tx2.makeProtoBody())
    }

    internal func testFromProtoBody() throws {
        let protoData = Proto_FileDeleteTransactionBody.with { proto in
            proto.fileID = FileId(num: 6006).toProtobuf()
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.fileDelete = protoData
            proto.transactionID = Resources.txId.toProtobuf()
        }

        let tx = try FileDeleteTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.fileId, 6006)
    }

    internal func testGetSetFileId() {
        let tx = FileDeleteTransaction()

        tx.fileId(1234)

        XCTAssertEqual(tx.fileId, 1234)
    }
}
