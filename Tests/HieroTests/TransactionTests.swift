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

internal final class TransactionTests: XCTestCase {
    internal func testToFromBytes() throws {
        let new = TransferTransaction()

        let bytes = try new.maxTransactionFee(10).transactionValidDuration(Duration.seconds(119))
            .transactionMemo("Frosted flakes").hbarTransfer(AccountId(2), 2).hbarTransfer(AccountId(101), -2)
            .transactionId(Resources.txId).nodeAccountIds(Resources.nodeAccountIds).freeze().toBytes()

        let tx = new

        let lhs = try tx.makeProtoBody()

        let tx2 = try Transaction.fromBytes(bytes)

        let rhs = try tx2.makeProtoBody()

        XCTAssertEqual(tx.maxTransactionFee, tx2.maxTransactionFee)

        let lhs1 = tx.nodeAccountIds
        let rhs2 = tx2.nodeAccountIds

        XCTAssertEqual(lhs1, rhs2)

        XCTAssertEqual(tx.transactionId, tx2.transactionId)
        XCTAssertEqual(tx.transactionMemo, tx2.transactionMemo)
        XCTAssertEqual(tx.transactionValidDuration, tx2.transactionValidDuration)
        XCTAssertEqual(lhs, rhs)
        XCTAssertNotNil(tx2.sources)
    }

    internal func testFromBytesSignToBytes() throws {
        let new = TransferTransaction()

        let bytes = try new.maxTransactionFee(10).transactionValidDuration(Duration.seconds(119))
            .transactionMemo("Frosted flakes").hbarTransfer(AccountId(2), 2).hbarTransfer(AccountId(101), -2)
            .transactionId(Resources.txId).nodeAccountIds(Resources.nodeAccountIds).freeze().toBytes()

        let tx2 = try Transaction.fromBytes(bytes)

        tx2.sign(
            try PrivateKey.fromBytes(
                Data(
                    hexEncoded:
                        "302e020100300506032b657004220420e40d4241d093b22910c78135e0501b137cd9205bbb9c0153c5adf2c65e7dc95a"
                )!))

        _ = try tx2.toBytes()

        XCTAssertEqual(tx2.signers.count, 1)
    }

    internal func testChunkedToFromBytes() throws {
        let client = Client.forTestnet()
        client.setOperator(AccountId(0), PrivateKey.generateEd25519())

        let bytes = try TopicMessageSubmitTransaction().topicId(314).message("Fish cutlery".data(using: .utf8)!)
            .chunkSize(8).maxChunks(2).transactionId(Resources.txId).nodeAccountIds(Resources.nodeAccountIds)
            .freezeWith(client).toBytes()

        let tx = try Transaction.fromBytes(bytes)

        _ = try tx.toBytes()
    }
}
