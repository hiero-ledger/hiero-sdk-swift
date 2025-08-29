// SPDX-License-Identifier: Apache-2.0

import Hiero
import XCTest

internal final class AccountInfo: XCTestCase {
    internal func testQuery() async throws {
        let testEnv = try TestEnvironment.nonFree

        let info = try await AccountInfoQuery(accountId: testEnv.operator.accountId)
            .execute(testEnv.client)

        XCTAssertEqual(info.accountId, testEnv.operator.accountId)
        XCTAssertFalse(info.isDeleted)
        XCTAssertEqual(info.key, .single(testEnv.operator.privateKey.publicKey))
        XCTAssertGreaterThan(info.balance, 0)

        // fixme: ensure no warning gets emitted.
        // XCTAssertNil(info.proxyAccountId)
        XCTAssertEqual(info.proxyReceived, 0)
    }

    internal func testQueryCostForOperator() async throws {
        let testEnv = try TestEnvironment.nonFree

        let query = AccountInfoQuery(accountId: testEnv.operator.accountId)
            .maxPaymentAmount(Hbar(1))

        let cost = try await query.getCost(testEnv.client)

        let info = try await query.paymentAmount(cost).execute(testEnv.client)

        XCTAssertEqual(info.accountId, testEnv.operator.accountId)
    }

    internal func testQueryCostBigMax() async throws {
        let testEnv = try TestEnvironment.nonFree

        let query = AccountInfoQuery(accountId: testEnv.operator.accountId)
            .maxPaymentAmount(.max)

        let cost = try await query.getCost(testEnv.client)

        let info = try await query.paymentAmount(cost).execute(testEnv.client)

        XCTAssertEqual(info.accountId, testEnv.operator.accountId)
    }

    internal func testQueryCostSmallMaxFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        let query = AccountInfoQuery(accountId: testEnv.operator.accountId)
            .maxPaymentAmount(.fromTinybars(1))

        let cost = try await query.getCost(testEnv.client)

        await assertThrowsHErrorAsync(
            try await query.execute(testEnv.client),
            "expected error querying account"
        ) { error in
            // note: there's a very small chance this fails if the cost of a AccountInfoQuery changes right when we execute it.
            XCTAssertEqual(error.kind, .maxQueryPaymentExceeded(queryCost: cost, maxQueryPayment: .fromTinybars(1)))
        }
    }

    internal func disabledTestGetCostInsufficientTxFeeFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        await assertThrowsHErrorAsync(
            try await AccountInfoQuery()
                .accountId(testEnv.operator.accountId)
                .maxPaymentAmount(.fromTinybars(10000))
                .paymentAmount(.fromTinybars(1))
                .execute(testEnv.client),
            "expected error querying account"
        ) { error in
            guard case .queryPaymentPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.queryPaymentPreCheckStatus`")
                return
            }
            // note: there's a very small chance this fails if the cost of a AccountInfoQuery changes right when we execute it.
            XCTAssertEqual(status, .insufficientTxFee)
        }
    }

    internal func testFlowVerifySignedTransaction() async throws {
        let testEnv = try TestEnvironment.nonFree

        let transaction = try AccountCreateTransaction()
            .freezeWith(testEnv.client)
            .signWithOperator(testEnv.client)

        try await AccountInfoFlow.verifyTransactionSignature(testEnv.client, testEnv.operator.accountId, transaction)
    }

    internal func testFlowVerifyUnsignedTransactionFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        let unsignedTx = try AccountCreateTransaction()
            .freezeWith(testEnv.client)

        await assertThrowsHErrorAsync(
            try await AccountInfoFlow
                .verifyTransactionSignature(testEnv.client, testEnv.operator.accountId, unsignedTx),
            "expected `verifyTransactionSignature` to throw error"
        ) { error in
            XCTAssertEqual(error.kind, .signatureVerify)
        }
    }
}
