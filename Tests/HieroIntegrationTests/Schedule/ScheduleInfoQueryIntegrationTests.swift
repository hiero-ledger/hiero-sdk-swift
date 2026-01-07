// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal class ScheduleInfoQueryIntegrationTests: HieroIntegrationTestCase {

    internal func test_Query() async throws {
        // Given
        let (accountId, _) = try await createTestAccount(initialBalance: TestConstants.testSmallHbarBalance)
        let scheduleId = try await createUnmanagedSchedule(standardScheduledTransfer(from: accountId))

        // When
        let info = try await ScheduleInfoQuery(scheduleId: scheduleId).execute(testEnv.client)

        // Then
        XCTAssertEqual(info.adminKey, nil)
        XCTAssertEqual(info.creatorAccountId, testEnv.operator.accountId)
        XCTAssertNil(info.deletedAt)
        assertScheduleNotExecuted(info)
        XCTAssertNotNil(info.expirationTime)
        XCTAssertEqual(info.memo, "")
        XCTAssertEqual(info.payerAccountId, testEnv.operator.accountId)
        _ = try info.scheduledTransaction
        XCTAssertEqual(info.signatories, [.single(testEnv.operator.privateKey.publicKey)])
        XCTAssertFalse(info.waitForExpiry)
    }

    internal func test_MissingScheduleIdFails() async throws {
        // Given / When / Then
        await assertQueryNoPaymentPrecheckStatus(
            try await ScheduleInfoQuery().execute(testEnv.client),
            .invalidScheduleID
        )
    }

    internal func test_QueryCost() async throws {
        // Given
        let (accountId, _) = try await createTestAccount(initialBalance: TestConstants.testSmallHbarBalance)
        let scheduleId = try await createSchedule(
            standardScheduledTransferWithAdminKey(from: accountId),
            adminKey: testEnv.operator.privateKey
        )

        let query = ScheduleInfoQuery(scheduleId: scheduleId)
        let cost = try await query.getCost(testEnv.client)

        // When / Then
        _ = try await query.paymentAmount(cost).execute(testEnv.client)
    }

    internal func test_QueryCostBigMax() async throws {
        // Given
        let (accountId, _) = try await createTestAccount(initialBalance: TestConstants.testSmallHbarBalance)
        let scheduleId = try await createSchedule(
            standardScheduledTransferWithAdminKey(from: accountId),
            adminKey: testEnv.operator.privateKey
        )

        let query = ScheduleInfoQuery(scheduleId: scheduleId).maxPaymentAmount(Hbar(1000))
        let cost = try await query.getCost(testEnv.client)

        // When / Then
        _ = try await query.paymentAmount(cost).execute(testEnv.client)
    }

    internal func test_QueryCostSmallMaxFails() async throws {
        // Given
        let (accountId, _) = try await createTestAccount(initialBalance: TestConstants.testSmallHbarBalance)
        let scheduleId = try await createSchedule(
            standardScheduledTransferWithAdminKey(from: accountId),
            adminKey: testEnv.operator.privateKey
        )

        let query = ScheduleInfoQuery(scheduleId: scheduleId).maxPaymentAmount(.fromTinybars(1))
        let cost = try await query.getCost(testEnv.client)

        // When / Then
        await assertMaxQueryPaymentExceeded(
            try await query.execute(testEnv.client),
            queryCost: cost,
            maxQueryPayment: .fromTinybars(1)
        )
    }

    internal func test_QueryCostInsufficientTxFeeFails() async throws {
        // Given
        let (accountId, _) = try await createTestAccount(initialBalance: TestConstants.testSmallHbarBalance)
        let scheduleId = try await createSchedule(
            standardScheduledTransferWithAdminKey(from: accountId),
            adminKey: testEnv.operator.privateKey
        )

        // When / Then
        await assertQueryPaymentPrecheckStatus(
            try await ScheduleInfoQuery()
                .scheduleId(scheduleId)
                .maxPaymentAmount(.fromTinybars(10000))
                .paymentAmount(.fromTinybars(1))
                .execute(testEnv.client),
            .insufficientTxFee
        )
    }
}
