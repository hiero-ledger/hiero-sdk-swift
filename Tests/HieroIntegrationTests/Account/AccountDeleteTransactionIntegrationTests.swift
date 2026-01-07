// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal final class AccountDeleteTransactionIntegrationTests: HieroIntegrationTestCase {
    internal func test_CreateThenDelete() async throws {
        // Given
        let (accountId, key) = try await createSimpleUnmanagedAccount(
            initialBalance: TestConstants.testSmallHbarBalance)

        // When
        _ = try await AccountDeleteTransaction()
            .transferAccountId(testEnv.operator.accountId)
            .accountId(accountId)
            .sign(key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        await assertQueryNoPaymentPrecheckStatus(
            try await AccountInfoQuery(accountId: accountId).execute(testEnv.client),
            .accountDeleted
        )
    }

    internal func test_MissingAccountIdFails() async throws {
        // Given / When / Then
        await assertPrecheckStatus(
            try await AccountDeleteTransaction()
                .transferAccountId(testEnv.operator.accountId)
                .execute(testEnv.client),
            .accountIDDoesNotExist
        )
    }

    internal func test_MissingDeleteeSignatureFails() async throws {
        // Given
        let key = PrivateKey.generateEd25519()
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(key.publicKey))
                .initialBalance(1),
            key: key
        )

        // When / Then
        await assertReceiptStatus(
            try await AccountDeleteTransaction()
                .transferAccountId(testEnv.operator.accountId)
                .accountId(accountId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )
    }
}
