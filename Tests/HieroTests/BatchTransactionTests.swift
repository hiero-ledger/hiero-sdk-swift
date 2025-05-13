// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal class BatchTransactionTests: XCTestCase {
    private static let transactionId = TransactionId.generateFrom(AccountId(num: 1))
    private static let batchKey = try! PrivateKey.fromStringEcdsa(
        "7f109a9e3b0d8ecfba9cc23a3614433ce0fa7ddcc80f2a8f10b222179a5a80d6")

    private static func makeMockTx() throws -> TransferTransaction {
        return try TransferTransaction()
            .transactionId(transactionId)
            .batchKey(batchKey)
            .freeze()
            .sign(batchKey)
    }

    private static func makeTransaction() throws -> BatchTransaction {
        return BatchTransaction().addInnerTransaction(makeMockTx()).addInnerTransaction(makeMockTx())
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

    internal func testProperties() throws {
        let tx = try Self.makeTransaction()

        XCTAssertEqual(tx.transactions.count, 2)
    }

    internal func testGetSetTransactions() throws {
        let tx = BatchTransaction()
        tx.transactions = [makeMockTx()]

        XCTAssertEqual(tx.transactions.count, 1)
    }

    internal func testGetSetInnerTransactions() throws {
        let tx = BatchTransaction()
        tx.innerTransactions([makeMockTx()])

        XCTAssertEqual(tx.transactions.count, 1)
    }

    internal func testGetSetAddInnerTransactions() throws {
        let tx = BatchTransaction()
        tx.addInnerTransaction(makeMockTx())

        XCTAssertEqual(tx.transactions.count, 1)
    }
}
