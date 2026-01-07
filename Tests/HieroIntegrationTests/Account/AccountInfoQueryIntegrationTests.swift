// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal final class AccountInfoQueryIntegrationTests: HieroIntegrationTestCase {
    internal func test_Query() async throws {
        // Given / When
        let info = try await AccountInfoQuery(accountId: testEnv.operator.accountId)
            .execute(testEnv.client)

        // Then
        assertAccountInfo(
            info, accountId: testEnv.operator.accountId, key: .single(testEnv.operator.privateKey.publicKey))
        XCTAssertGreaterThan(info.balance, 0)
        XCTAssertEqual(info.proxyReceived, 0)
    }

    internal func test_QueryCostForOperator() async throws {
        // Given
        let query = AccountInfoQuery(accountId: testEnv.operator.accountId)
            .maxPaymentAmount(Hbar(1))
        let cost = try await query.getCost(testEnv.client)

        // When
        let info = try await query.paymentAmount(cost).execute(testEnv.client)

        // Then
        XCTAssertEqual(info.accountId, testEnv.operator.accountId)
    }

    internal func test_QueryCostBigMax() async throws {
        // Given
        let query = AccountInfoQuery(accountId: testEnv.operator.accountId)
            .maxPaymentAmount(.max)
        let cost = try await query.getCost(testEnv.client)

        // When
        let info = try await query.paymentAmount(cost).execute(testEnv.client)

        // Then
        XCTAssertEqual(info.accountId, testEnv.operator.accountId)
    }

    internal func test_QueryCostSmallMaxFails() async throws {
        // Given
        let query = AccountInfoQuery(accountId: testEnv.operator.accountId)
            .maxPaymentAmount(.fromTinybars(1))
        let cost = try await query.getCost(testEnv.client)

        // When / Then
        await assertMaxQueryPaymentExceeded(
            try await query.execute(testEnv.client),
            queryCost: cost,
            maxQueryPayment: .fromTinybars(1)
        )
    }

    internal func test_GetCostInsufficientTxFeeFails() async throws {
        // Given / When / Then
        await assertQueryPaymentPrecheckStatus(
            try await AccountInfoQuery()
                .accountId(testEnv.operator.accountId)
                .maxPaymentAmount(.fromTinybars(10000))
                .paymentAmount(.fromTinybars(1))
                .execute(testEnv.client),
            .insufficientTxFee
        )
    }

    internal func test_FlowVerifySignedTransaction() async throws {
        // Given
        let transaction = try AccountCreateTransaction()
            .freezeWith(testEnv.client)
            .signWithOperator(testEnv.client)

        // When / Then
        try await AccountInfoFlow.verifyTransactionSignature(testEnv.client, testEnv.operator.accountId, transaction)
    }

    internal func test_FlowVerifyUnsignedTransactionFails() async throws {
        // Given
        let unsignedTx = try AccountCreateTransaction()
            .freezeWith(testEnv.client)

        // When / Then
        await assertThrowsHErrorAsync(
            try await AccountInfoFlow
                .verifyTransactionSignature(testEnv.client, testEnv.operator.accountId, unsignedTx),
            "expected `verifyTransactionSignature` to throw error"
        ) { error in
            XCTAssertEqual(error.kind, .signatureVerify)
        }
    }
}
