// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal class TokenRevokeKycTransactionIntegrationTests: HieroIntegrationTestCase {
    internal func test_Basic() async throws {
        // Given
        let (accountId, accountKey) = try await createTestAccount()

        let kycKey = PrivateKey.generateEd25519()
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .treasuryAccountId(testEnv.operator.accountId)
                .kycKey(.single(kycKey.publicKey))
        )

        try await associateToken(tokenId, with: accountId, key: accountKey)

        // When / Then
        _ = try await TokenRevokeKycTransaction()
            .accountId(accountId)
            .tokenId(tokenId)
            .freezeWith(testEnv.client)
            .sign(kycKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    internal func test_MissingTokenId() async throws {
        // Given / When / Then
        await assertPrecheckStatus(
            try await TokenRevokeKycTransaction()
                .accountId(testEnv.operator.accountId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidTokenID
        )
    }

    internal func test_MissingAccountIdFails() async throws {
        // Given
        let kycKey = PrivateKey.generateEd25519()
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .treasuryAccountId(testEnv.operator.accountId)
                .kycKey(.single(kycKey.publicKey))
        )

        // When / Then
        await assertPrecheckStatus(
            try await TokenRevokeKycTransaction()
                .tokenId(tokenId)
                .sign(kycKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidAccountID
        )
    }

    internal func test_UnassociatedTokenFails() async throws {
        // Given
        let (accountId, _) = try await createTestAccount()

        let kycKey = PrivateKey.generateEd25519()
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .treasuryAccountId(testEnv.operator.accountId)
                .kycKey(.single(kycKey.publicKey))
        )

        // When / Then
        await assertReceiptStatus(
            try await TokenRevokeKycTransaction()
                .accountId(accountId)
                .tokenId(tokenId)
                .freezeWith(testEnv.client)
                .sign(kycKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .tokenNotAssociatedToAccount
        )
    }
}
