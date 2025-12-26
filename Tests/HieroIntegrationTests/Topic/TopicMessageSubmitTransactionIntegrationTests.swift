// SPDX-License-Identifier: Apache-2.0

import HieroExampleUtilities
import HieroTestSupport
import XCTest

@testable import Hiero

internal class TopicMessageSubmitTransactionIntegrationTests: HieroIntegrationTestCase {
    internal func test_Basic() async throws {
        // Given
        let topicId = try await createStandardTopic()

        // When
        _ = try await TopicMessageSubmitTransaction()
            .topicId(topicId)
            .message("Hello, from HCS!".data(using: .utf8)!)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        let info = try await TopicInfoQuery(topicId: topicId).execute(testEnv.client)
        assertStandardTopicInfo(info, topicId: topicId)
        XCTAssertEqual(info.sequenceNumber, 1)
    }

    internal func test_LargeMessage() async throws {
        // Given
        let bigContents = Resources.bigContents.data(using: .utf8)!
        let topicId = try await createStandardTopic()

        // When
        let responses = try await TopicMessageSubmitTransaction()
            .topicId(topicId)
            .maxChunks(15)
            .message(bigContents)
            .executeAll(testEnv.client)

        for response in responses {
            _ = try await response.getReceipt(testEnv.client)
        }

        // Then
        let info = try await TopicInfoQuery(topicId: topicId).execute(testEnv.client)
        assertStandardTopicInfo(info, topicId: topicId)
        XCTAssertEqual(info.sequenceNumber, 14)
    }

    internal func test_MissingTopicIdFails() async throws {
        // Given
        let bigContents = Resources.bigContents.data(using: .utf8)!

        // When / Then
        await assertPrecheckStatus(
            try await TopicMessageSubmitTransaction()
                .maxChunks(15)
                .message(bigContents)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidTopicID
        )
    }

    internal func test_MissingMessageFails() async throws {
        // Given
        let topicId = try await createStandardTopic()

        // When / Then
        await assertPrecheckStatus(
            try await TopicMessageSubmitTransaction()
                .topicId(topicId)
                .execute(testEnv.client),
            .invalidTopicMessage
        )
    }

    internal func test_DecodeHexRegressionTest() throws {
        // Given
        let transactionBytes = Data(
            hexEncoded:
                """
                2ac2010a580a130a0b08d38f8f880610a09be91512041899e11c120218041880\
                c2d72f22020878da01330a0418a5a12012103030303030303136323736333737\
                31351a190a130a0b08d38f8f880610a09be91512041899e11c1001180112660a\
                640a20603edaec5d1c974c92cb5bee7b011310c3b84b13dc048424cd6ef146d6\
                a0d4a41a40b6a08f310ee29923e5868aac074468b2bde05da95a806e2f4a4f45\
                2177f129ca0abae7831e595b5beaa1c947e2cb71201642bab33fece5184b0454\
                7afc40850a
                """
        )!

        // When
        let transaction = try Transaction.fromBytes(transactionBytes)

        // Then
        _ = try XCTUnwrap(transaction.transactionId)
    }

    internal func disabledTestChargesHbarFeeWithLimitsApplied() async throws {
        // Given
        let hbarAmount: UInt64 = 100_000_000
        let privateKey = PrivateKey.generateEcdsa()
        let customFixedFee = CustomFixedFee(hbarAmount / 2, testEnv.operator.accountId)

        let topicId = try await createTopic(
            TopicCreateTransaction()
                .adminKey(.single(testEnv.operator.privateKey.publicKey))
                .feeScheduleKey(.single(testEnv.operator.privateKey.publicKey))
                .addCustomFee(customFixedFee),
            adminKey: testEnv.operator.privateKey
        )

        let accountId = try await createAccount(
            AccountCreateTransaction()
                .initialBalance(TestConstants.testSmallHbarBalance)
                .keyWithoutAlias(Key.single(privateKey.publicKey)),
            key: privateKey
        )

        testEnv.client.setOperator(accountId, privateKey)

        // When
        _ = try await TopicMessageSubmitTransaction()
            .topicId(topicId)
            .message(Data("Hello, Hedera™ hashgraph!".utf8))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        testEnv.client.setOperator(testEnv.operator.accountId, PrivateKey.generateEcdsa())

        // Then
        let accountInfo = try await AccountBalanceQuery()
            .accountId(accountId)
            .execute(testEnv.client)

        XCTAssertLessThan(accountInfo.hbars.toTinybars(), Int64(hbarAmount / 2))
    }

    // This test is to ensure that the fee exempt keys are exempted from the custom fee
    internal func disabledTestExemptsFeeExemptKeysFromHbarFees() async throws {
        // Given
        let hbarAmount: UInt64 = 100_000_000
        let feeExemptKey1 = PrivateKey.generateEcdsa()
        let feeExemptKey2 = PrivateKey.generateEcdsa()

        let customFixedFee = CustomFixedFee(hbarAmount / 2, testEnv.operator.accountId)

        let topicId = try await createTopic(
            try TopicCreateTransaction()
                .adminKey(.single(testEnv.operator.privateKey.publicKey))
                .feeScheduleKey(.single(testEnv.operator.privateKey.publicKey))
                .feeExemptKeys([.single(feeExemptKey1.publicKey), .single(feeExemptKey2.publicKey)])
                .addCustomFee(customFixedFee)
                .freezeWith(testEnv.client)
                .sign(testEnv.operator.privateKey),
            adminKey: testEnv.operator.privateKey
        )

        let payerAccountId = try await createAccount(
            AccountCreateTransaction()
                .initialBalance(TestConstants.testSmallHbarBalance)
                .keyWithoutAlias(Key.single(feeExemptKey1.publicKey)),
            key: feeExemptKey1
        )

        testEnv.client.setOperator(payerAccountId, feeExemptKey1)

        // When
        _ = try await TopicMessageSubmitTransaction()
            .topicId(topicId)
            .message(Data("Hello, Hedera™ hashgraph!".utf8))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        testEnv.client.setOperator(payerAccountId, PrivateKey.generateEcdsa())

        // Then
        let accountInfo = try await AccountBalanceQuery()
            .accountId(payerAccountId)
            .execute(testEnv.client)

        XCTAssertGreaterThan(accountInfo.hbars.toTinybars(), Int64(hbarAmount / 2))
    }

    // MARK: - Scheduled Transactions with Custom Fee Limits

    /// Creates a revenue-generating topic with the given custom fee.
    private func createRevenueGeneratingTopic(customFee: CustomFixedFee) async throws -> TopicId {
        try await createTopic(
            TopicCreateTransaction()
                .adminKey(.single(testEnv.operator.privateKey.publicKey))
                .feeScheduleKey(.single(testEnv.operator.privateKey.publicKey))
                .addCustomFee(customFee),
            adminKey: testEnv.operator.privateKey
        )
    }

    /// Creates a payer account with unlimited token associations.
    private func createPayerWithTokenAssociation(initialBalance: Hbar = Hbar(1)) async throws -> (AccountId, PrivateKey)
    {
        let payerKey = PrivateKey.generateEcdsa()
        let payerAccountId = try await createAccount(
            AccountCreateTransaction()
                .initialBalance(initialBalance)
                .maxAutomaticTokenAssociations(TestConstants.testUnlimitedTokenAssociations)
                .keyWithoutAlias(Key.single(payerKey.publicKey)),
            key: payerKey
        )
        return (payerAccountId, payerKey)
    }

    /// Transfers tokens from the operator to the specified account.
    private func transferTokens(_ tokenId: TokenId, to accountId: AccountId, amount: Int64) async throws {
        _ = try await TransferTransaction()
            .tokenTransfer(tokenId, testEnv.operator.accountId, -amount)
            .tokenTransfer(tokenId, accountId, amount)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    /// Asserts that a scheduled transaction failed with the expected status.
    /// Handles both immediate execution and deferred execution scenarios.
    /// - Throws: `HError` if the schedule wasn't created (error occurred at precheck)
    private func assertScheduledTransactionStatus(
        _ response: TransactionResponse,
        expectedStatus: Status,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let receipt = try await TransactionReceiptQuery()
            .transactionId(response.transactionId)
            .includeChildren(true)
            .execute(testEnv.client)

        // If no scheduleId, the error might be in the receipt status or children
        guard let scheduleId = receipt.scheduleId else {
            // Check if the expected error is in the receipt status or children
            if receipt.status == expectedStatus {
                return  // Test passed - error is in the receipt status
            }
            if receipt.children.contains(where: { $0.status == expectedStatus }) {
                return  // Test passed - error is in children
            }
            XCTFail(
                "Expected scheduleId in receipt, or expected \(expectedStatus) in receipt status/children. Got status: \(receipt.status)",
                file: file, line: line)
            return
        }

        let scheduleInfo = try await ScheduleInfoQuery()
            .scheduleId(scheduleId)
            .execute(testEnv.client)

        if let executedAt = scheduleInfo.executedAt {
            guard let scheduledTxId = receipt.scheduledTransactionId else {
                XCTFail(
                    "Expected scheduledTransactionId when schedule executed at \(executedAt)", file: file, line: line)
                return
            }

            await assertReceiptStatus(
                try await TransactionReceiptQuery()
                    .transactionId(scheduledTxId)
                    .validateStatus(true)
                    .execute(testEnv.client),
                expectedStatus,
                file: file,
                line: line
            )
        } else {
            let hasExpectedError =
                receipt.children.contains { $0.status == expectedStatus }
                || receipt.status == expectedStatus

            XCTAssertTrue(
                hasExpectedError,
                "Expected \(expectedStatus) status, got receipt status: \(receipt.status), children: \(receipt.children.map { $0.status })",
                file: file,
                line: line
            )
        }
    }

    internal func test_ChargesHbarsWithLimitUsingScheduledTransaction() async throws {
        // Given
        let hbarAmount: UInt64 = 100_000_000
        let customFixedFee = CustomFixedFee(hbarAmount / 2, testEnv.operator.accountId)
        let topicId = try await createRevenueGeneratingTopic(customFee: customFixedFee)
        let (payerAccountId, payerKey) = try await createTestAccount(initialBalance: Hbar(1))

        let customFeeLimit = CustomFeeLimit(
            payerId: payerAccountId,
            customFees: [customFixedFee]
        )

        testEnv.client.setOperator(payerAccountId, payerKey)

        // When
        _ = try await TopicMessageSubmitTransaction()
            .topicId(topicId)
            .message(Data("Hello, Hedera!".utf8))
            .addCustomFeeLimit(customFeeLimit)
            .schedule()
            .expirationTime(.now + .days(1))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        testEnv.client.setOperator(testEnv.operator.accountId, testEnv.operator.privateKey)

        // Then
        let accountBalance = try await AccountBalanceQuery()
            .accountId(payerAccountId)
            .execute(testEnv.client)

        XCTAssertLessThan(accountBalance.hbars.toTinybars(), Int64(hbarAmount / 2))
    }

    internal func test_ChargesTokensWithLimitUsingScheduledTransaction() async throws {
        // Given
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .initialSupply(10)
                .treasuryAccountId(testEnv.operator.accountId)
        )

        let customFixedFee = CustomFixedFee(1, testEnv.operator.accountId, tokenId)
        let topicId = try await createRevenueGeneratingTopic(customFee: customFixedFee)
        let (payerAccountId, payerKey) = try await createPayerWithTokenAssociation(
            initialBalance: TestConstants.testMediumHbarBalance)
        try await transferTokens(tokenId, to: payerAccountId, amount: 1)

        let customFeeLimit = CustomFeeLimit(
            payerId: payerAccountId,
            customFees: [CustomFixedFee(1, nil, tokenId)]
        )

        // When
        testEnv.client.setOperator(payerAccountId, payerKey)

        _ = try await TopicMessageSubmitTransaction()
            .topicId(topicId)
            .message(Data("Hello, Hedera!".utf8))
            .addCustomFeeLimit(customFeeLimit)
            .schedule()
            .expirationTime(.now + .days(1))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        testEnv.client.setOperator(testEnv.operator.accountId, testEnv.operator.privateKey)

        // Then
        let accountBalance = try await AccountBalanceQuery()
            .accountId(payerAccountId)
            .execute(testEnv.client)

        XCTAssertEqual(accountBalance.tokenBalances[tokenId], 0)
    }

    internal func test_DoesNotChargeHbarsWithLowerLimitUsingScheduledTransaction() async throws {
        // Given
        let hbarAmount: UInt64 = 100_000_000
        let customFixedFee = CustomFixedFee(hbarAmount / 2, testEnv.operator.accountId)
        let topicId = try await createRevenueGeneratingTopic(customFee: customFixedFee)
        let (payerAccountId, payerKey) = try await createTestAccount(initialBalance: Hbar(1))

        let customFeeLimit = CustomFeeLimit(
            payerId: payerAccountId,
            customFees: [CustomFixedFee(hbarAmount / 2 - 1, nil, nil)]
        )

        testEnv.client.setOperator(payerAccountId, payerKey)

        // When
        let response = try await TopicMessageSubmitTransaction()
            .topicId(topicId)
            .message(Data("Hello, Hedera!".utf8))
            .addCustomFeeLimit(customFeeLimit)
            .schedule()
            .expirationTime(.now + .days(1))
            .execute(testEnv.client)

        testEnv.client.setOperator(testEnv.operator.accountId, testEnv.operator.privateKey)

        // Then
        try await assertScheduledTransactionStatus(response, expectedStatus: .maxCustomFeeLimitExceeded)
    }

    internal func test_DoesNotChargeTokensWithLowerLimitUsingScheduledTransaction() async throws {
        // Given
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .initialSupply(10)
                .treasuryAccountId(testEnv.operator.accountId)
        )

        let customFixedFee = CustomFixedFee(2, testEnv.operator.accountId, tokenId)
        let topicId = try await createRevenueGeneratingTopic(customFee: customFixedFee)
        let (payerAccountId, payerKey) = try await createPayerWithTokenAssociation()
        try await transferTokens(tokenId, to: payerAccountId, amount: 2)

        let customFeeLimit = CustomFeeLimit(
            payerId: payerAccountId,
            customFees: [CustomFixedFee(1, nil, tokenId)]
        )

        testEnv.client.setOperator(payerAccountId, payerKey)

        // When
        let response = try await TopicMessageSubmitTransaction()
            .topicId(topicId)
            .message(Data("Hello, Hedera!".utf8))
            .addCustomFeeLimit(customFeeLimit)
            .schedule()
            .expirationTime(.now + .days(1))
            .execute(testEnv.client)

        testEnv.client.setOperator(testEnv.operator.accountId, testEnv.operator.privateKey)

        // Then
        try await assertScheduledTransactionStatus(response, expectedStatus: .maxCustomFeeLimitExceeded)
    }

    internal func test_DoesNotExecuteWithInvalidCustomFeeLimitUsingScheduledTransaction() async throws {
        // Given
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .initialSupply(10)
                .treasuryAccountId(testEnv.operator.accountId)
        )

        let customFixedFee = CustomFixedFee(2, testEnv.operator.accountId, tokenId)
        let topicId = try await createRevenueGeneratingTopic(customFee: customFixedFee)
        let (payerAccountId, payerKey) = try await createPayerWithTokenAssociation()
        try await transferTokens(tokenId, to: payerAccountId, amount: 2)

        testEnv.client.setOperator(payerAccountId, payerKey)

        // Test 1: Invalid token ID (0.0.0) - should fail with NO_VALID_MAX_CUSTOM_FEE
        let invalidTokenCustomFeeLimit = CustomFeeLimit(
            payerId: payerAccountId,
            customFees: [CustomFixedFee(1, nil, TokenId(num: 0))]
        )

        let response1 = try await TopicMessageSubmitTransaction()
            .topicId(topicId)
            .message(Data("Hello, Hedera!".utf8))
            .addCustomFeeLimit(invalidTokenCustomFeeLimit)
            .schedule()
            .expirationTime(.now + .days(1))
            .execute(testEnv.client)

        try await assertScheduledTransactionStatus(response1, expectedStatus: .noValidMaxCustomFee)

        // Test 2: Duplicate denomination - should fail with DUPLICATE_DENOMINATION_IN_MAX_CUSTOM_FEE_LIST
        let duplicateDenominationCustomFeeLimit = CustomFeeLimit(
            payerId: payerAccountId,
            customFees: [
                CustomFixedFee(1, nil, tokenId),
                CustomFixedFee(2, nil, tokenId),
            ]
        )

        // May fail at precheck or during scheduled execution
        do {
            let response2 = try await TopicMessageSubmitTransaction()
                .topicId(topicId)
                .message(Data("Hello, Hedera!".utf8))
                .addCustomFeeLimit(duplicateDenominationCustomFeeLimit)
                .schedule()
                .expirationTime(.now + .days(1))
                .execute(testEnv.client)

            try await assertScheduledTransactionStatus(
                response2, expectedStatus: .duplicateDenominationInMaxCustomFeeList)
        } catch let error as HError {
            // Error might occur at precheck
            switch error.kind {
            case .transactionPreCheckStatus(let status, transactionId: _):
                XCTAssertEqual(status, .duplicateDenominationInMaxCustomFeeList)
            case .receiptStatus(let status, transactionId: _):
                XCTAssertEqual(status, .duplicateDenominationInMaxCustomFeeList)
            default:
                XCTFail("Unexpected error type: \(error.kind)")
            }
        }

        testEnv.client.setOperator(testEnv.operator.accountId, testEnv.operator.privateKey)
    }
}
