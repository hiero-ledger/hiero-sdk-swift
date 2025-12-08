// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

// Note: FileAppendTransaction has special chunked data handling, so it doesn't use TransactionTestable
internal final class FileAppendTransactionUnitTests: HieroUnitTestCase {
    private static let fileId = FileId("0.0.10")
    private static let contents = "{foo: 231}".data(using: .utf8)!

    private static func makeTransaction() throws -> FileAppendTransaction {
        try FileAppendTransaction()
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .maxTransactionFee(Hbar(2))
            .sign(TestConstants.privateKey)
            .fileId(fileId)
            .contents(contents)
            .freeze()
    }

    /// Helper to verify transaction body fields for chunked transactions
    private static func checkTransactionBody(body: Proto_TransactionBody) throws -> Proto_TransactionBody.OneOf_Data {
        let nodeAccountId = body.nodeAccountID

        XCTAssertEqual(body.transactionID, TestConstants.transactionId.toProtobuf())
        XCTAssert(TestConstants.nodeAccountIds.contains(try AccountId.fromProtobuf(nodeAccountId)))
        XCTAssertEqual(body.transactionFee, UInt64(Hbar(2).toTinybars()))
        XCTAssertEqual(body.transactionValidDuration, Duration.seconds(120).toProtobuf())
        XCTAssertEqual(body.generateRecord, false)
        XCTAssertEqual(body.memo, "")

        return body.data!
    }

    internal func test_Serialize() throws {
        let tx = try Self.makeTransaction()

        // Unlike most transactions, this iteration makes sure the chunked data is properly handled.
        // NOTE: Without a client, dealing with chunked data is cumbersome.
        let bodyBytes = try tx.makeSources().signedTransactions.makeIterator().map { signed in
            try Proto_TransactionBody.init(serializedBytes: signed.bodyBytes)
        }

        let txes = try bodyBytes.makeIterator().map { bytes in
            try Self.checkTransactionBody(body: bytes)
        }

        SnapshotTesting.assertSnapshot(of: txes, as: .description)
    }

    internal func test_ToFromBytes() throws {
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

    internal func test_GetSetFileId() throws {
        let tx = FileAppendTransaction.init()
        tx.fileId(Self.fileId)

        XCTAssertEqual(tx.fileId, Self.fileId)
    }

    internal func test_GetSetContents() throws {
        let tx = FileAppendTransaction.init()
        tx.contents(Self.contents)

        XCTAssertEqual(tx.contents, Self.contents)
    }
}
