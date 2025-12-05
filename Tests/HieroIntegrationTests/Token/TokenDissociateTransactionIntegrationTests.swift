// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal class TokenDissociateTransactionIntegrationTests: HieroIntegrationTestCase {
    internal func test_Basic() async throws {
        // Given
        let (accountId, accountKey) = try await createTestAccount()
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .treasuryAccountId(testEnv.operator.accountId)
        )

        try await associateToken(tokenId, with: accountId, key: accountKey)

        // When / Then
        _ = try await TokenDissociateTransaction()
            .accountId(accountId)
            .tokenIds([tokenId])
            .sign(accountKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    internal func test_MissingTokenId() async throws {
        // Given / When / Then
        _ = try await TokenDissociateTransaction()
            .accountId(testEnv.operator.accountId)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    internal func test_MissingAccountIdFails() async throws {
        // Given / When / Then
        await assertPrecheckStatus(
            try await TokenDissociateTransaction()
                .execute(testEnv.client),
            .invalidAccountID
        )
    }

    internal func test_MissingSignatureFails() async throws {
        // Given
        let (accountId, _) = try await createTestAccount()

        // When / Then
        await assertReceiptStatus(
            try await TokenDissociateTransaction()
                .accountId(accountId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )
    }

    internal func test_UnassociatedTokenFails() async throws {
        // Given
        let (accountId, accountKey) = try await createTestAccount()

        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .treasuryAccountId(testEnv.operator.accountId)
        )

        // When / Then
        await assertReceiptStatus(
            try await TokenDissociateTransaction()
                .accountId(accountId)
                .tokenIds([tokenId])
                .freezeWith(testEnv.client)
                .sign(accountKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .tokenNotAssociatedToAccount
        )
    }
}
