// SPDX-License-Identifier: Apache-2.0

import Hiero
import XCTest

internal final class BatchTests: XCTestCase {
    internal func testBatchOneTransaction() async throws {
        let testEnv = try TestEnvironment.nonFree

        let key = PrivateKey.generateEd25519()
        let batchKey = PrivateKey.generateEcdsa()
        let accountCreateTx = try AccountCreateTransaction()
            .keyWithoutAlias(.single(key.publicKey))
            .initialBalance(Hbar(1))
            .batchify(client: testEnv.client, .single(batchKey.publicKey))
            .freezeWith(testEnv.client)

        let batchTx = try BatchTransaction()
            .addInnerTransaction(accountCreateTx)
            .freezeWith(testEnv.client)
            .sign(batchKey)
        let batchReceipt = try await batchTx.execute(testEnv.client).getReceipt(testEnv.client)

        XCTAssertEqual(batchReceipt.status, .success)

        let transactionIds = batchTx.innerTransactionIds
        XCTAssertEqual(transactionIds.count, 1)

        let accountCreateReceipt = try await TransactionReceiptQuery()
            .transactionId(transactionIds[0]).execute(testEnv.client)
        let accountId = try XCTUnwrap(accountCreateReceipt.accountId)

        addTeardownBlock { try await Account(id: accountId, key: key).delete(testEnv) }

        let info = try await AccountInfoQuery(accountId: accountId).execute(testEnv.client)

        XCTAssertEqual(info.accountId, accountId)
    }

    internal func testBatchMaxTransactions() async throws {
        let testEnv = try TestEnvironment.nonFree

        let key = PrivateKey.generateEd25519()
        let batchKey = PrivateKey.generateEcdsa()
        let accountCreateTx = try AccountCreateTransaction()
            .keyWithoutAlias(.single(key.publicKey))
            .initialBalance(Hbar(1))
            .batchify(client: testEnv.client, .single(batchKey.publicKey))
            .freezeWith(testEnv.client)

        var batchTx = BatchTransaction()
        for _ in 0..<25 {
            try batchTx.addInnerTransaction(accountCreateTx)
        }

        batchTx = try batchTx
            .freezeWith(testEnv.client)
            .sign(batchKey)
        let batchReceipt = try await batchTx.execute(testEnv.client).getReceipt(testEnv.client)

        XCTAssertEqual(batchReceipt.status, .success)

        let transactionIds = batchTx.innerTransactionIds
        XCTAssertEqual(transactionIds.count, 25)

        let accountCreateReceipt = try await TransactionReceiptQuery()
            .transactionId(transactionIds[0]).execute(testEnv.client)
        let accountId = try XCTUnwrap(accountCreateReceipt.accountId)

        addTeardownBlock { try await Account(id: accountId, key: key).delete(testEnv) }

        let info = try await AccountInfoQuery(accountId: accountId).execute(testEnv.client)

        XCTAssertEqual(info.accountId, accountId)
    }

    internal func testEmptyBatchTransaction() async throws {
        let testEnv = try TestEnvironment.nonFree

        await assertThrowsHErrorAsync(
            try await BatchTransaction().execute(testEnv.client),
            "expected error empty batch transaction"
        ) { error in
            guard case .transactionPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("\(error.kind) is not `.transactionPreCheckStatus(status: _)`")
                return
            }

            XCTAssertEqual(status, .batchListEmpty)
        }
    }

    internal func testBlacklistedBatchTransaction() async throws {
        let testEnv = try TestEnvironment.nonFree

        await assertThrowsHErrorAsync(
            try await BatchTransaction()
                .addInnerTransaction(BatchTransaction().freezeWith(testEnv.client))
                .execute(testEnv.client),
            "expected error blacklisted batch transaction"
        ) { error in
            guard case .transactionPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("\(error.kind) is not `.transactionPreCheckStatus(status: _)`")
                return
            }

            XCTAssertEqual(status, .batchListEmpty)
        }
    }

    internal func testChunkedBatchTransaction() async throws {
        let testEnv = try TestEnvironment.nonFree

        let key = PrivateKey.generateEd25519()
        let batchKey = PrivateKey.generateEcdsa()
        let topicId = try await TopicCreateTransaction().execute(testEnv.client).getReceipt(testEnv.client).topicId!

        let topicMsgSubmitTx = try TopicMessageSubmitTransaction()
            .topicId(topicId)
            .message("Hello from HCS!".data(using: .utf8) ?? Data())
            .batchify(client: testEnv.client, .single(batchKey.publicKey))

        let batchTx = try BatchTransaction()
            .addInnerTransaction(topicMsgSubmitTx)
            .freezeWith(testEnv.client)
            .sign(batchKey)
        let batchReceipt = try await batchTx.execute(testEnv.client).getReceipt(testEnv.client)

        XCTAssertEqual(batchReceipt.status, .success)

        let info = try await TopicInfoQuery(topicId: topicId).execute(testEnv.client)

        XCTAssertEqual(info.topicId, topicId)
    }

    internal func testMultipleBatchKeysBatchTransactions() async throws {
        let testEnv = try TestEnvironment.nonFree

        let batchKey1 = PrivateKey.generateEcdsa()
        let batchKey2 = PrivateKey.generateEcdsa()
        let batchKey3 = PrivateKey.generateEcdsa()

        let accountKey1 = PrivateKey.generateEcdsa()
        let accountKey2 = PrivateKey.generateEcdsa()
        let accountKey3 = PrivateKey.generateEcdsa()

        let accountId1 = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(accountKey1.publicKey))
            .initialBalance(Hbar(2))
            .execute(testEnv.client)
            .getReceipt(testEnv.client).accountId!
        let accountId2 = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(accountKey2.publicKey))
            .initialBalance(Hbar(2))
            .execute(testEnv.client)
            .getReceipt(testEnv.client).accountId!
        let accountId3 = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(accountKey3.publicKey))
            .initialBalance(Hbar(2))
            .execute(testEnv.client)
            .getReceipt(testEnv.client).accountId!

        addTeardownBlock { try await Account(id: accountId1, key: accountKey1).delete(testEnv) }
        addTeardownBlock { try await Account(id: accountId2, key: accountKey2).delete(testEnv) }
        addTeardownBlock { try await Account(id: accountId3, key: accountKey3).delete(testEnv) }

        let accountTx1 = try TransferTransaction()
            .hbarTransfer(testEnv.operator.accountId, Hbar(-1))
            .hbarTransfer(accountId1, Hbar(1))
            .freezeWith(testEnv.client)
            .sign(accountKey1)
            .batchify(client: testEnv.client, .single(batchKey1.publicKey))
        let accountTx2 = try TransferTransaction()
            .hbarTransfer(testEnv.operator.accountId, Hbar(-1))
            .hbarTransfer(accountId2, Hbar(1))
            .freezeWith(testEnv.client)
            .sign(accountKey2)
            .batchify(client: testEnv.client, .single(batchKey2.publicKey))
        let accountTx3 = try TransferTransaction()
            .hbarTransfer(testEnv.operator.accountId, Hbar(-1))
            .hbarTransfer(accountId3, Hbar(1))
            .freezeWith(testEnv.client)
            .sign(accountKey3)
            .batchify(client: testEnv.client, .single(batchKey3.publicKey))

        let batchTxReceipt = try await BatchTransaction()
            .addInnerTransaction(accountTx1)
            .addInnerTransaction(accountTx2)
            .addInnerTransaction(accountTx3)
            .freezeWith(testEnv.client)
            .sign(batchKey1)
            .sign(batchKey2)
            .sign(batchKey3)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        XCTAssertEqual(batchTxReceipt.status, .success)
    }

    internal func testBatchTransactionsFailButIncurFees() async throws {
        let testEnv = try TestEnvironment.nonFree

        let initialOperatorBalance = try await AccountBalanceQuery().accountId(testEnv.operator.accountId).execute(
            testEnv.client
        ).hbars

        let accountKey1 = PrivateKey.generateEcdsa()
        let accountKey2 = PrivateKey.generateEcdsa()
        let accountKey3 = PrivateKey.generateEcdsa()

        let accountTx1 = try AccountCreateTransaction()
            .keyWithoutAlias(.single(accountKey1.publicKey))
            .initialBalance(Hbar(1))
            .batchify(client: testEnv.client, .single(testEnv.operator.privateKey.publicKey))
        let accountTx2 = try AccountCreateTransaction()
            .keyWithoutAlias(.single(accountKey2.publicKey))
            .initialBalance(Hbar(1))
            .batchify(client: testEnv.client, .single(testEnv.operator.privateKey.publicKey))
        let accountTx3 = try AccountCreateTransaction()
            .keyWithoutAlias(.single(accountKey3.publicKey))
            .initialBalance(Hbar(1))
            .receiverSignatureRequired(true)
            .batchify(client: testEnv.client, .single(testEnv.operator.privateKey.publicKey))

        await assertThrowsHErrorAsync(
            try await BatchTransaction()
                .addInnerTransaction(accountTx1)
                .addInnerTransaction(accountTx2)
                .addInnerTransaction(accountTx3)
                .execute(testEnv.client),
            "expected inner transaction failure"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("\(error.kind) is not `.receiptStatus(status: _)`")
                return
            }

            XCTAssertEqual(status, .innerTransactionFailed)
        }

        let finalOperatorBalance = try await AccountBalanceQuery().accountId(testEnv.operator.accountId).execute(
            testEnv.client
        ).hbars

        XCTAssertLessThan(finalOperatorBalance, initialOperatorBalance)
    }

    internal func testBatchifiedTxButNotInBatch() async throws {
        let testEnv = try TestEnvironment.nonFree

        await assertThrowsHErrorAsync(
            try await TopicCreateTransaction()
                .adminKey(.single(testEnv.operator.privateKey.publicKey))
                .batchify(client: testEnv.client, .single(testEnv.operator.privateKey.publicKey))
                .execute(testEnv.client),
            "expected error batchified tx not in batch"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("\(error.kind) is not `.receiptStatus(status: _)`")
                return
            }

            XCTAssertEqual(status, .batchKeySetOnNonInnerTransaction)
        }
    }
}
