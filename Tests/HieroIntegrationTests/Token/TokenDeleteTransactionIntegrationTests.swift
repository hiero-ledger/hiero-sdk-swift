// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal class TokenDeleteTransactionIntegrationTests: HieroIntegrationTestCase {
    internal func test_Basic() async throws {
        // Given
        let adminKey = PrivateKey.generateEd25519()

        let tokenId = try await createUnmanagedToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .treasuryAccountId(testEnv.operator.accountId)
                .adminKey(.single(adminKey.publicKey))
                .expirationTime(.now + .minutes(5))
                .sign(adminKey)
        )

        // When / Then
        _ = try await TokenDeleteTransaction(tokenId: tokenId)
            .sign(adminKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    internal func test_MissingAdminKeySignatureFails() async throws {
        // Given
        let adminKey = PrivateKey.generateEd25519()
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .treasuryAccountId(testEnv.operator.accountId)
                .adminKey(.single(adminKey.publicKey))
                .expirationTime(.now + .minutes(5))
                .sign(adminKey),
            adminKey: adminKey
        )

        // When / Then
        await assertReceiptStatus(
            try await TokenDeleteTransaction()
                .tokenId(tokenId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )
    }

    internal func test_MissingTokenIdFails() async throws {
        // Given / When / Then
        await assertPrecheckStatus(
            try await TokenDeleteTransaction()
                .execute(testEnv.client),
            .invalidTokenID
        )
    }
}
