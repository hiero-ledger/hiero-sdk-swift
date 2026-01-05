// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal final class AccountBalanceQueryIntegrationTests: HieroIntegrationTestCase {
    internal func test_Query() async throws {
        // Given / When
        let balance = try await AccountBalanceQuery(accountId: testEnv.operator.accountId).execute(testEnv.client)

        // Then
        assertAccountBalance(balance, accountId: testEnv.operator.accountId)
    }

    internal func test_QueryCost() async throws {
        // Given
        let query = AccountBalanceQuery()
        query.accountId(testEnv.operator.accountId).maxPaymentAmount(1)
        let cost = try await query.getCost(testEnv.client)

        // When
        let balance = try await query.paymentAmount(cost).execute(testEnv.client)

        // Then
        assertAccountBalance(balance, accountId: testEnv.operator.accountId)
    }

    internal func test_QueryCostBigMax() async throws {
        // Given
        let query = AccountBalanceQuery()
        query.accountId(testEnv.operator.accountId).maxPaymentAmount(1_000_000)
        let cost = try await query.getCost(testEnv.client)

        // When
        let balance = try await query.paymentAmount(cost).execute(testEnv.client)

        // Then
        assertAccountBalance(balance, accountId: testEnv.operator.accountId)
    }

    internal func test_QueryCostSmallMax() async throws {
        // Given
        let query = AccountBalanceQuery()
        query.accountId(testEnv.operator.accountId).maxPaymentAmount(.fromTinybars(1))
        let cost = try await query.getCost(testEnv.client)

        // When
        let balance = try await query.paymentAmount(cost).execute(testEnv.client)

        // Then
        assertAccountBalance(balance, accountId: testEnv.operator.accountId)
    }

    internal func test_InvalidAccountIdFails() async throws {
        // Given / When / Then
        await assertQueryNoPaymentPrecheckStatus(
            try await AccountBalanceQuery(accountId: "1.0.3").execute(testEnv.client),
            .invalidAccountID
        )
    }
}
