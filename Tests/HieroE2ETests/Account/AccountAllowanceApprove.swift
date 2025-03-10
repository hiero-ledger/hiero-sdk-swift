// SPDX-License-Identifier: Apache-2.0

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
