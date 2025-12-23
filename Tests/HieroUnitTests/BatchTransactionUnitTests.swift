// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal class BatchTransactionUnitTests: HieroUnitTestCase, TransactionTestable {
    typealias TransactionType = BatchTransaction

    private static let transactionId = TransactionId.generateFrom(AccountId(num: 1))
    private static let batchKey = try! PrivateKey.fromStringEcdsa(
        "7f109a9e3b0d8ecfba9cc23a3614433ce0fa7ddcc80f2a8f10b222179a5a80d6")

    private static func makeMockTx() throws -> AccountCreateTransaction {
        return try AccountCreateTransaction()
            .nodeAccountIds([AccountId(0)])
            .transactionId(TestConstants.transactionId)
            .keyWithoutAlias(.single(batchKey.publicKey))
            .initialBalance(Hbar(1))
            .batchKey(.single(batchKey.publicKey))
            .freeze()
            .sign(batchKey)
    }

    static func makeTransaction() throws -> BatchTransaction {
        return try BatchTransaction()
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .addInnerTransaction(try makeMockTx())
            .addInnerTransaction(try makeMockTx())
            .freeze()
    }

    internal func test_Serialize() throws {
        try assertTransactionSerializes()
    }

    internal func test_ToFromBytes() throws {
        try assertTransactionRoundTrips()
    }

    internal func test_Properties() throws {
        let tx = try Self.makeTransaction()

        XCTAssertEqual(tx.transactions.count, 2)
    }

    internal func test_GetSetTransactions() throws {
        let tx = BatchTransaction()
        tx.transactions = [try BatchTransactionUnitTests.makeMockTx()]

        XCTAssertEqual(tx.transactions.count, 1)
    }

    internal func test_GetSetInnerTransactions() throws {
        let tx = BatchTransaction()
        tx.innerTransactions([try BatchTransactionUnitTests.makeMockTx()])

        XCTAssertEqual(tx.transactions.count, 1)
    }

    internal func test_GetSetAddInnerTransactions() throws {
        let tx = BatchTransaction()
        tx.addInnerTransaction(try BatchTransactionUnitTests.makeMockTx())

        XCTAssertEqual(tx.transactions.count, 1)
    }
}
