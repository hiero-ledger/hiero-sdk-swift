// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal class ScheduleDeleteTransactionIntegrationTests: HieroIntegrationTestCase {
    internal func test_Basic() async throws {
        // Given
        let (accountId, _) = try await createTestAccount(initialBalance: TestConstants.testSmallHbarBalance)
        let scheduleId = try await createUnmanagedSchedule(
            standardScheduledTransferWithAdminKey(from: accountId)
        )

        // When / Then
        _ = try await ScheduleDeleteTransaction(scheduleId: scheduleId)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    internal func test_MissingAdminKeyFails() async throws {
        // Given
        let (accountId, _) = try await createTestAccount(initialBalance: TestConstants.testSmallHbarBalance)
        let scheduleId = try await createUnmanagedSchedule(standardScheduledTransfer(from: accountId))

        // When / Then
        await assertReceiptStatus(
            try await ScheduleDeleteTransaction(scheduleId: scheduleId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .scheduleIsImmutable
        )
    }

    internal func test_DoubleDeleteFails() async throws {
        // Given
        let (accountId, _) = try await createTestAccount(initialBalance: TestConstants.testSmallHbarBalance)
        let scheduleId = try await createUnmanagedSchedule(
            standardScheduledTransferWithAdminKey(from: accountId)
        )

        _ = try await ScheduleDeleteTransaction(scheduleId: scheduleId)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // When /Then
        await assertReceiptStatus(
            try await ScheduleDeleteTransaction(scheduleId: scheduleId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .scheduleAlreadyDeleted
        )
    }

    internal func test_MissingScheduleIdFails() async throws {
        // Given / When / Then
        await assertPrecheckStatus(
            try await ScheduleDeleteTransaction()
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidScheduleID
        )
    }
}
