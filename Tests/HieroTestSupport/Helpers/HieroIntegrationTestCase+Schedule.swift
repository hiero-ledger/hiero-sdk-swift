// SPDX-License-Identifier: Apache-2.0

/// Schedule helper methods for integration tests.
///
/// This extension provides methods for creating, registering, and asserting schedules in integration tests.
/// Schedules created with `createSchedule` are automatically registered for cleanup at test teardown.

import Foundation
import Hiero
import XCTest

// MARK: - Schedule Helpers

extension HieroIntegrationTestCase {

    // MARK: - Unmanaged Schedule Creation

    /// Creates a schedule from a transaction without registering it for cleanup.
    ///
    /// Use this when you need full control over the schedule lifecycle or when testing
    /// scenarios where cleanup would interfere with the test.
    ///
    /// - Parameters:
    ///   - transaction: Pre-configured `ScheduleCreateTransaction` (before execute)
    ///   - useAdminClient: Whether to use the admin client (default: false)
    /// - Returns: The created schedule ID
    public func createUnmanagedSchedule(_ transaction: ScheduleCreateTransaction, useAdminClient: Bool = false)
        async throws -> ScheduleId
    {
        let receipt =
            try await transaction
            .execute(useAdminClient ? testEnv.adminClient : testEnv.client)
            .getReceipt(useAdminClient ? testEnv.adminClient : testEnv.client)
        return try XCTUnwrap(receipt.scheduleId)
    }

    // MARK: - Schedule Registration

    /// Registers an existing schedule for automatic cleanup at test teardown.
    ///
    /// - Parameters:
    ///   - scheduleId: The schedule ID to register
    ///   - adminKey: Private key for schedule deletion
    public func registerSchedule(_ scheduleId: ScheduleId, adminKey: PrivateKey) async {
        await registerSchedule(scheduleId, adminKeys: [adminKey])
    }

    /// Registers an existing schedule for automatic cleanup at test teardown (multiple keys).
    ///
    /// - Parameters:
    ///   - scheduleId: The schedule ID to register
    ///   - adminKeys: Private keys required for schedule deletion
    public func registerSchedule(_ scheduleId: ScheduleId, adminKeys: [PrivateKey]) async {
        await resourceManager.registerCleanup(priority: .schedules) { [client = testEnv.client] in
            let transaction = ScheduleDeleteTransaction(scheduleId: scheduleId)
            for key in adminKeys {
                transaction.sign(key)
            }
            _ = try await transaction.execute(client).getReceipt(client)
        }
    }

    // MARK: - Managed Schedule Creation

    /// Creates a schedule and registers it for automatic cleanup.
    ///
    /// - Parameters:
    ///   - transaction: Pre-configured `ScheduleCreateTransaction` (before execute)
    ///   - adminKey: Private key for schedule deletion
    ///   - useAdminClient: Whether to use the admin client (default: false)
    /// - Returns: The created schedule ID
    public func createSchedule(
        _ transaction: ScheduleCreateTransaction,
        adminKey: PrivateKey,
        useAdminClient: Bool = false
    ) async throws -> ScheduleId {
        try await createSchedule(transaction, adminKeys: [adminKey], useAdminClient: useAdminClient)
    }

    /// Creates a schedule and registers it for automatic cleanup (multiple keys).
    ///
    /// - Parameters:
    ///   - transaction: Pre-configured `ScheduleCreateTransaction` (before execute)
    ///   - adminKeys: Private keys required for schedule deletion
    ///   - useAdminClient: Whether to use the admin client (default: false)
    /// - Returns: The created schedule ID
    public func createSchedule(
        _ transaction: ScheduleCreateTransaction,
        adminKeys: [PrivateKey],
        useAdminClient: Bool = false
    ) async throws -> ScheduleId {
        let scheduleId = try await createUnmanagedSchedule(transaction, useAdminClient: useAdminClient)
        await registerSchedule(scheduleId, adminKeys: adminKeys)
        return scheduleId
    }

    // MARK: - Convenience Schedule Creation

    /// Creates a standard scheduled transfer from an account to the operator.
    ///
    /// This creates the `ScheduleCreateTransaction` but does not execute it.
    /// Useful for tests that need to customize the schedule before creation.
    ///
    /// - Parameters:
    ///   - accountId: Source account for the transfer
    ///   - amount: Amount to transfer (default: TestConstants.testSmallHbarBalance)
    /// - Returns: A configured `ScheduleCreateTransaction`
    public func standardScheduledTransfer(
        from accountId: AccountId,
        amount: Hbar = TestConstants.testSmallHbarBalance
    ) -> ScheduleCreateTransaction {
        TransferTransaction()
            .hbarTransfer(accountId, -amount)
            .hbarTransfer(testEnv.operator.accountId, amount)
            .schedule()
    }

    /// Creates a standard scheduled transfer with operator admin key.
    ///
    /// This creates the `ScheduleCreateTransaction` but does not execute it.
    ///
    /// - Parameters:
    ///   - accountId: Source account for the transfer
    ///   - amount: Amount to transfer (default: TestConstants.testSmallHbarBalance)
    /// - Returns: A configured `ScheduleCreateTransaction` with admin key
    public func standardScheduledTransferWithAdminKey(
        from accountId: AccountId,
        amount: Hbar = TestConstants.testSmallHbarBalance
    ) -> ScheduleCreateTransaction {
        standardScheduledTransfer(from: accountId, amount: amount)
            .adminKey(.single(testEnv.operator.privateKey.publicKey))
    }

    // MARK: - ScheduleInfo Assertions

    /// Asserts that a schedule has been executed.
    ///
    /// - Parameter info: Schedule info to validate
    public func assertScheduleExecuted(
        _ info: ScheduleInfo,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertNotNil(info.executedAt, "Schedule should have been executed", file: file, line: line)
    }

    /// Asserts that a schedule has not been executed.
    ///
    /// - Parameter info: Schedule info to validate
    public func assertScheduleNotExecuted(
        _ info: ScheduleInfo,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertNil(info.executedAt, "Schedule should not have been executed", file: file, line: line)
    }
}
