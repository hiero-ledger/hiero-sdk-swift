// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal class ScheduleCreateTransactionIntegrationTests: HieroIntegrationTestCase {

    internal func test_Transfer() async throws {
        // Given
        let key1 = PrivateKey.generateEd25519()
        let key2 = PrivateKey.generateEd25519()
        let key3 = PrivateKey.generateEd25519()

        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(
                    .keyList([
                        .single(key1.publicKey),
                        .single(key2.publicKey),
                        .single(key3.publicKey),
                    ])
                )
                .initialBalance(TestConstants.testSmallHbarBalance),
            keys: [key1, key2, key3]
        )

        // When
        let scheduleId = try await createSchedule(
            standardScheduledTransferWithAdminKey(from: accountId),
            adminKeys: [testEnv.operator.privateKey])

        // Then
        let info = try await ScheduleInfoQuery(scheduleId: scheduleId).execute(testEnv.client)
        assertScheduleNotExecuted(info)
    }

    internal func test_DoubleScheduleFails() async throws {
        // Given
        let (accountId, _) = try await createTestAccount(initialBalance: TestConstants.testSmallHbarBalance)

        let scheduleId = try await createUnmanagedSchedule(
            TransferTransaction()
                .hbarTransfer(testEnv.operator.accountId, -TestConstants.testSmallHbarBalance)
                .hbarTransfer(accountId, TestConstants.testSmallHbarBalance)
                .schedule())
        let info = try await ScheduleInfoQuery(scheduleId: scheduleId).execute(testEnv.client)
        assertScheduleExecuted(info)

        // When / Then
        await assertReceiptStatus(
            try await TransferTransaction()
                .hbarTransfer(testEnv.operator.accountId, -TestConstants.testSmallHbarBalance)
                .hbarTransfer(accountId, TestConstants.testSmallHbarBalance)
                .schedule()
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .identicalScheduleAlreadyCreated
        )
    }

    internal func test_TopicMessage() async throws {
        // Given
        let submitKey = PrivateKey.generateEd25519()
        let topicId = try await createTopic(
            TopicCreateTransaction()
                .adminKey(.single(testEnv.operator.privateKey.publicKey))
                .autoRenewAccountId(testEnv.operator.accountId)
                .topicMemo("HCS Topic_")
                .submitKey(.single(submitKey.publicKey)),
            adminKey: testEnv.operator.privateKey
        )

        // When
        let scheduleId = try await createUnmanagedSchedule(
            TopicMessageSubmitTransaction()
                .topicId(topicId)
                .message("scheduled hcs message".data(using: .utf8)!)
                .schedule()
                .adminKey(.single(testEnv.operator.privateKey.publicKey))
                .payerAccountId(testEnv.operator.accountId)
                .scheduleMemo("mirror scheduled E2E signature on create and sign_\(Date())")
        )

        // Then
        let info = try await ScheduleInfoQuery(scheduleId: scheduleId).execute(testEnv.client)
        XCTAssertEqual(info.scheduleId, scheduleId)
    }

    internal func test_ScheduleAheadOneYearFail() async throws {
        // Given
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(testEnv.operator.privateKey.publicKey))
                .initialBalance(TestConstants.testMediumHbarBalance),
            keys: [testEnv.operator.privateKey]
        )

        // When / Then
        await assertReceiptStatus(
            try await TransferTransaction()
                .hbarTransfer(testEnv.operator.accountId, TestConstants.testSmallHbarBalance)
                .hbarTransfer(accountId, -TestConstants.testSmallHbarBalance)
                .schedule()
                .expirationTime(.now + .days(365))
                .scheduleMemo("HIP-423 e2e Test")
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .scheduleExpirationTimeTooFarInFuture
        )
    }

    internal func test_ScheduleInThePastFail() async throws {
        // Given
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(testEnv.operator.privateKey.publicKey))
                .initialBalance(TestConstants.testMediumHbarBalance),
            keys: [testEnv.operator.privateKey]
        )

        // When / Then
        await assertReceiptStatus(
            try await TransferTransaction()
                .hbarTransfer(testEnv.operator.accountId, TestConstants.testSmallHbarBalance)
                .hbarTransfer(accountId, -TestConstants.testSmallHbarBalance)
                .schedule()
                .expirationTime(.now - .seconds(10))
                .scheduleMemo("HIP-423 e2e Test")
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .scheduleExpirationTimeMustBeHigherThanConsensusTime
        )
    }
}
