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

internal final class TransactionChunkInfoTests: XCTestCase {
    internal func testInitial() throws {
        let info = ChunkInfo.initial(total: 2, transactionId: Resources.txId, nodeAccountId: Resources.accountId)

        XCTAssertEqual(info.current, 0)
        XCTAssertEqual(info.total, 2)
        XCTAssertEqual(info.currentTransactionId, Resources.txId)
        XCTAssertEqual(info.initialTransactionId, Resources.txId)
        XCTAssertEqual(info.nodeAccountId, Resources.accountId)
    }

    internal func testArguments() throws {
        let info = ChunkInfo(
            current: 3, total: 4, initialTransactionId: Resources.txId, currentTransactionId: Resources.txId,
            nodeAccountId: Resources.nodeAccountIds[0])

        XCTAssertEqual(info.current, 3)
        XCTAssertEqual(info.total, 4)
        XCTAssertEqual(info.currentTransactionId, Resources.txId)
        XCTAssertEqual(info.initialTransactionId, Resources.txId)
        XCTAssertEqual(info.nodeAccountId, Resources.nodeAccountIds[0])
    }

    internal func testSingle() throws {
        let info = ChunkInfo.single(transactionId: Resources.txId, nodeAccountId: Resources.nodeAccountIds[0])

        XCTAssertEqual(info.current, 0)
        XCTAssertEqual(info.total, 1)
        XCTAssertEqual(info.currentTransactionId, Resources.txId)
        XCTAssertEqual(info.initialTransactionId, Resources.txId)
        XCTAssertEqual(info.nodeAccountId, Resources.nodeAccountIds[0])
    }
}
