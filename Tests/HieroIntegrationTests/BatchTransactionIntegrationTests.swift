// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal final class BatchTransactionIntegrationTests: HieroIntegrationTestCase {

    internal func test_BatchOneTransaction() async throws {
        // Given
        let key = PrivateKey.generateEd25519()
        let batchKey = PrivateKey.generateEcdsa()
        let accountCreateTx = try AccountCreateTransaction()
            .keyWithoutAlias(.single(key.publicKey))
            .initialBalance(Hbar(1))
            .batchify(client: testEnv.client, .single(batchKey.publicKey))

        let batchTx = try BatchTransaction()
            .addInnerTransaction(accountCreateTx)
            .freezeWith(testEnv.client)
            .sign(batchKey)

        // When
        _ = try await batchTx.execute(testEnv.client).getReceipt(testEnv.client)

        // Then
        let transactionIds = batchTx.innerTransactionIds
        let accountCreateReceipt = try await TransactionReceiptQuery()
            .transactionId(transactionIds[0])
            .execute(testEnv.client)
        let accountId = try XCTUnwrap(accountCreateReceipt.accountId)
        await registerAccount(accountId, key: key)

        let info = try await AccountInfoQuery(accountId: accountId).execute(testEnv.client)
        XCTAssertEqual(info.accountId, accountId)
    }

    internal func test_BatchDuplicateTransactions() async throws {
        // Given
        let key = PrivateKey.generateEd25519()
        let batchKey = PrivateKey.generateEcdsa()
        let accountCreateTx = try AccountCreateTransaction()
            .keyWithoutAlias(.single(key.publicKey))
            .initialBalance(Hbar(1))
            .batchify(client: testEnv.client, .single(batchKey.publicKey))

        // When / Then
        await assertPrecheckStatus(
            try await BatchTransaction()
                .addInnerTransaction(accountCreateTx)
                .addInnerTransaction(accountCreateTx)
                .sign(batchKey)
                .execute(testEnv.client),
            .batchListContainsDuplicates
        )
    }

    internal func test_EmptyBatchTransaction() async throws {
        // Given / When / Then
        await assertPrecheckStatus(
            try await BatchTransaction().execute(testEnv.client),
            .batchListEmpty
        )
    }

    internal func test_BlacklistedBatchTransaction() async throws {
        // Given
        let batchKey = PrivateKey.generateEcdsa()

        // When / Then
        await assertReceiptStatus(
            try await BatchTransaction()
                .addInnerTransaction(
                    ScheduleCreateTransaction()
                        .scheduleMemo("Hello from HCS!")
                        .scheduledTransaction(TopicCreateTransaction())
                        .batchify(client: testEnv.client, .single(batchKey.publicKey))
                )
                .sign(batchKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .batchTransactionInBlacklist
        )
    }

    internal func test_ChunkedBatchTransaction() async throws {
        // Given
        let batchKey = PrivateKey.generateEcdsa()
        let topicId = try await createStandardTopic()

        let topicMsgSubmitTx = try TopicMessageSubmitTransaction()
            .topicId(topicId)
            .message("Hello from HCS!".data(using: .utf8) ?? Data())
            .batchify(client: testEnv.client, .single(batchKey.publicKey))

        // When
        _ = try await BatchTransaction()
            .addInnerTransaction(topicMsgSubmitTx)
            .freezeWith(testEnv.client)
            .sign(batchKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        let info = try await TopicInfoQuery(topicId: topicId).execute(testEnv.client)
        XCTAssertEqual(info.topicId, topicId)
    }

    internal func test_MultipleBatchKeysBatchTransactions() async throws {
        // Given
        let batchKey1 = PrivateKey.generateEcdsa()
        let batchKey2 = PrivateKey.generateEcdsa()
        let batchKey3 = PrivateKey.generateEcdsa()

        let (accountId1, accountKey1) = try await createTestAccount(initialBalance: TestConstants.testMediumHbarBalance)
        let (accountId2, accountKey2) = try await createTestAccount(initialBalance: TestConstants.testMediumHbarBalance)
        let (accountId3, accountKey3) = try await createTestAccount(initialBalance: TestConstants.testMediumHbarBalance)

        let accountTx1 = try TransferTransaction()
            .hbarTransfer(testEnv.operator.accountId, Hbar(-1))
            .hbarTransfer(accountId1, Hbar(1))
            .batchify(client: testEnv.client, .single(batchKey1.publicKey))
            .sign(accountKey1)
        let accountTx2 = try TransferTransaction()
            .hbarTransfer(testEnv.operator.accountId, Hbar(-1))
            .hbarTransfer(accountId2, Hbar(1))
            .batchify(client: testEnv.client, .single(batchKey2.publicKey))
            .sign(accountKey2)
        let accountTx3 = try TransferTransaction()
            .hbarTransfer(testEnv.operator.accountId, Hbar(-1))
            .hbarTransfer(accountId3, Hbar(1))
            .batchify(client: testEnv.client, .single(batchKey3.publicKey))
            .sign(accountKey3)

        // When
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

        // Then
        XCTAssertEqual(batchTxReceipt.status, .success)
    }

    internal func test_BatchTransactionsFailButIncurFees() async throws {
        // Given
        let initialOperatorBalance = try await AccountBalanceQuery()
            .accountId(testEnv.operator.accountId)
            .execute(testEnv.client)
            .hbars

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

        // When
        await assertReceiptStatus(
            try await BatchTransaction()
                .addInnerTransaction(accountTx1)
                .addInnerTransaction(accountTx2)
                .addInnerTransaction(accountTx3)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .innerTransactionFailed
        )

        // Then
        let finalOperatorBalance = try await AccountBalanceQuery()
            .accountId(testEnv.operator.accountId)
            .execute(testEnv.client)
            .hbars
        XCTAssertLessThan(finalOperatorBalance, initialOperatorBalance)
    }

    internal func test_BatchifiedTxButNotInBatch() async throws {
        // Given / When / Then
        await assertReceiptStatus(
            try await TopicCreateTransaction()
                .batchify(client: testEnv.client, .single(testEnv.operator.privateKey.publicKey))
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .batchKeySetOnNonInnerTransaction
        )
    }
}
