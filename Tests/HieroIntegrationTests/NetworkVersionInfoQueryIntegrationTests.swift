// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal class NetworkVersionInfoQueryIntegrationTests: HieroIntegrationTestCase {
    internal func test_Query() async throws {
        // Given / When / Then
        _ = try await NetworkVersionInfoQuery().execute(testEnv.client)
    }

    internal func test_QueryCost() async throws {
        // Given
        let query = NetworkVersionInfoQuery().maxPaymentAmount(Hbar(1))
        let cost = try await query.getCost(testEnv.client)

        // When / Then
        _ = try await query.paymentAmount(cost).execute(testEnv.client)
    }

    internal func test_QueryCostBigMax() async throws {
        // Given
        let query = NetworkVersionInfoQuery().maxPaymentAmount(.max)
        let cost = try await query.getCost(testEnv.client)

        // When / Then
        _ = try await query.paymentAmount(cost).execute(testEnv.client)
    }

    internal func test_QueryCostSmallMaxFails() async throws {
        // Given
        let query = NetworkVersionInfoQuery().maxPaymentAmount(.fromTinybars(1))
        let cost = try await query.getCost(testEnv.client)

        // When / Then
        await assertThrowsHErrorAsync(
            try await query.execute(testEnv.client)
        ) { error in
            // note: there's a very small chance this fails if the cost of a FileContentsQuery changes right when we execute it.
            XCTAssertEqual(error.kind, .maxQueryPaymentExceeded(queryCost: cost, maxQueryPayment: .fromTinybars(1)))
        }
    }

    internal func disabledTestGetCostInsufficientTxFeeFails() async throws {
        // Given / When / Then
        await assertThrowsHErrorAsync(
            try await NetworkVersionInfoQuery()
                .maxPaymentAmount(.fromTinybars(10000))
                .paymentAmount(.fromTinybars(1))
                .execute(testEnv.client)
        ) { error in
            guard case .queryPaymentPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.queryPaymentPreCheckStatus`")
                return
            }

            XCTAssertEqual(status, .insufficientTxFee)
        }
    }
}
