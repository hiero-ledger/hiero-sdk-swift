// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal class TokenAssociateTransactionIntegrationTests: HieroIntegrationTestCase {
    internal func test_Basic() async throws {
        // Given
        let (accountId, accountKey) = try await createTestAccount()
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .treasuryAccountId(testEnv.operator.accountId)
        )

        // When / Then
        try await associateToken(tokenId, with: accountId, key: accountKey)
    }

    internal func test_MissingTokenId() async throws {
        // Given / When / Then
        _ = try await TokenAssociateTransaction()
            .accountId(testEnv.operator.accountId)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    internal func test_MissingAccountIdFails() async throws {
        // Given / When / Then
        await assertPrecheckStatus(
            try await TokenAssociateTransaction()
                .execute(testEnv.client),
            .invalidAccountID
        )
    }

    internal func test_MissingSignatureFails() async throws {
        // Given
        let (accountId, _) = try await createTestAccount()

        // When / Then
        await assertReceiptStatus(
            try await TokenAssociateTransaction()
                .accountId(accountId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )
    }
}
