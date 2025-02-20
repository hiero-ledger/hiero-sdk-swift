/*
 * ‌
 * Hedera Swift SDK
 * ​
 * Copyright (C) 2022 - 2024 Hedera Hashgraph, LLC
 * ​
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ‍
 */

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
