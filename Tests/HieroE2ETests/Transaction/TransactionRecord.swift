// SPDX-License-Identifier: Apache-2.0

import Hiero
import XCTest

internal class TransactionRecord: XCTestCase {
    internal func makeToken(_ testEnv: NonfreeTestEnvironment, _ account: Account) async throws -> Transaction.Response
    {
        try await TokenCreateTransaction()
            .name("ffff")
            .symbol("F")
            .treasuryAccountId(account.id)
            .expirationTime(.now + .minutes(5))
            .sign(account.key)
            .execute(testEnv.client)
    }

    internal func testQuery() async throws {
        let testEnv = try TestEnvironment.nonFree

        let account = try await Account.create(testEnv)

        let resp = try await makeToken(testEnv, account)

        let txId = try XCTUnwrap(resp.transactionId)
        let nodeAccountId = try XCTUnwrap(resp.nodeAccountId)
        let status = try XCTUnwrap(resp.validateStatus)

        let query = try await TransactionRecordQuery()
            .transactionId(txId)
            .nodeAccountIds([nodeAccountId])
            .validateStatus(status)
            .execute(testEnv.client)

        XCTAssertEqual(txId, query.transactionId)
    }

    internal func testQueryInvalidTxIdFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        let account = try await Account.create(testEnv)

        let resp = try await makeToken(testEnv, account)

        let nodeAccountId = try XCTUnwrap(resp.nodeAccountId)
        let status = try XCTUnwrap(resp.validateStatus)

        await assertThrowsHErrorAsync(
            try await TransactionRecordQuery()
                .nodeAccountIds([nodeAccountId])
                .validateStatus(status)
                .execute(testEnv.client)
        ) { error in
            guard case .queryNoPaymentPreCheckStatus(let status) = error.kind else {
                XCTFail("`\(error.kind)` is not `.queryPreCheckStatus`")
                return
            }

            XCTAssertEqual(status, .invalidTransactionID)
        }
    }
}
