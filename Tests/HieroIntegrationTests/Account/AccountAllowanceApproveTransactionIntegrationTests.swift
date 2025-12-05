// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal final class AccountAllowanceApproveTransactionIntegrationTests: HieroIntegrationTestCase {
    internal func test_Spend() async throws {
        // Given
        let (aliceAccountId, aliceKey) = try await createTestAccount(initialBalance: TestConstants.testMediumHbarBalance)
        let (bobAccountId, bobKey) = try await createTestAccount(initialBalance: TestConstants.testMediumHbarBalance)

        // When
        _ = try await AccountAllowanceApproveTransaction()
            .approveHbarAllowance(bobAccountId, aliceAccountId, 10)
            .freezeWith(testEnv.client)
            .sign(bobKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        let transferRecord = try await TransferTransaction()
            .hbarTransfer(testEnv.operator.accountId, 5)
            .approvedHbarTransfer(bobAccountId, -5)
            .transactionId(TransactionId.generateFrom(aliceAccountId))
            .freezeWith(testEnv.client)
            .sign(aliceKey)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        let transfer = try XCTUnwrap(transferRecord.transfers.first { $0.accountId == testEnv.operator.accountId })
        XCTAssertEqual(transfer.amount, 5)
    }
}
