// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal class BatchTransactionTests: XCTestCase {
    private static let transactionId = TransactionId.generateFrom(AccountId(num: 1))
    private static let batchKey = try! PrivateKey.fromStringEcdsa(
        "7f109a9e3b0d8ecfba9cc23a3614433ce0fa7ddcc80f2a8f10b222179a5a80d6")

    private static func makeMockTx() throws -> AccountCreateTransaction {
        return try AccountCreateTransaction()
            .nodeAccountIds([AccountId(0)])
            .transactionId(Resources.txId)
            .keyWithoutAlias(.single(batchKey.publicKey))
            .initialBalance(Hbar(1))
            .batchKey(.single(batchKey.publicKey))
            .freeze()
            .sign(batchKey)
    }

    private static func makeTransaction() throws -> BatchTransaction {
        return try BatchTransaction()
            .nodeAccountIds(Resources.nodeAccountIds)
            .transactionId(Resources.txId)
            .addInnerTransaction(try makeMockTx())
            .addInnerTransaction(try makeMockTx())
            .freeze()
    }

    internal func testSerialize() throws {
        let tx = try Self.makeTransaction().makeProtoBody()

        assertSnapshot(of: tx, as: .description)
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
        tx.transactions = [try BatchTransactionTests.makeMockTx()]

        XCTAssertEqual(tx.transactions.count, 1)
    }

    internal func testGetSetInnerTransactions() throws {
        let tx = BatchTransaction()
        tx.innerTransactions([try BatchTransactionTests.makeMockTx()])

        XCTAssertEqual(tx.transactions.count, 1)
    }

    internal func testGetSetAddInnerTransactions() throws {
        let tx = BatchTransaction()
        tx.addInnerTransaction(try BatchTransactionTests.makeMockTx())

        XCTAssertEqual(tx.transactions.count, 1)
    }
}
