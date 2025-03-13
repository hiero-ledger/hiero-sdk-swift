// SPDX-License-Identifier: Apache-2.0

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
