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

internal final class AccountAllowanceApprove: XCTestCase {
    internal func testSpend() async throws {
        let testEnv = try TestEnvironment.nonFree
        async let (alice, bob) = (makeAccount(testEnv, balance: 10), makeAccount(testEnv, balance: 10))

        _ = try await AccountAllowanceApproveTransaction()
            .approveHbarAllowance(bob.id, alice.id, 10)
            .freezeWith(testEnv.client)
            .sign(bob.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let transferRecord = try await TransferTransaction()
            .hbarTransfer(testEnv.operator.accountId, 5)
            .approvedHbarTransfer(bob.id, -5)
            .transactionId(TransactionId.generateFrom(alice.id))
            .freezeWith(testEnv.client)
            .sign(alice.key)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        let transfer = try XCTUnwrap(transferRecord.transfers.first { $0.accountId == testEnv.operator.accountId })
        XCTAssertEqual(transfer.amount, 5)
    }
}
