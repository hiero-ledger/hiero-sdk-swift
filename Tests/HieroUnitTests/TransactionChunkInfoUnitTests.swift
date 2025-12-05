// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class TransactionChunkInfoUnitTests: HieroUnitTestCase {
    internal func test_Initial() throws {
        let info = ChunkInfo.initial(total: 2, transactionId: TestConstants.transactionId, nodeAccountId: TestConstants.accountId)

        XCTAssertEqual(info.current, 0)
        XCTAssertEqual(info.total, 2)
        XCTAssertEqual(info.currentTransactionId, TestConstants.transactionId)
        XCTAssertEqual(info.initialTransactionId, TestConstants.transactionId)
        XCTAssertEqual(info.nodeAccountId, TestConstants.accountId)
    }

    internal func test_Arguments() throws {
        let info = ChunkInfo(
            current: 3, total: 4, initialTransactionId: TestConstants.transactionId, currentTransactionId: TestConstants.transactionId,
            nodeAccountId: TestConstants.nodeAccountIds[0])

        XCTAssertEqual(info.current, 3)
        XCTAssertEqual(info.total, 4)
        XCTAssertEqual(info.currentTransactionId, TestConstants.transactionId)
        XCTAssertEqual(info.initialTransactionId, TestConstants.transactionId)
        XCTAssertEqual(info.nodeAccountId, TestConstants.nodeAccountIds[0])
    }

    internal func test_Single() throws {
        let info = ChunkInfo.single(transactionId: TestConstants.transactionId, nodeAccountId: TestConstants.nodeAccountIds[0])

        XCTAssertEqual(info.current, 0)
        XCTAssertEqual(info.total, 1)
        XCTAssertEqual(info.currentTransactionId, TestConstants.transactionId)
        XCTAssertEqual(info.initialTransactionId, TestConstants.transactionId)
        XCTAssertEqual(info.nodeAccountId, TestConstants.nodeAccountIds[0])
    }
}
