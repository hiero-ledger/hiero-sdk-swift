// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal class TokenUnpauseTransactionIntegrationTests: HieroIntegrationTestCase {
    internal func test_Basic() async throws {
        // Given
        let pauseKey = PrivateKey.generateEd25519()
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .treasuryAccountId(testEnv.operator.accountId)
                .pauseKey(.single(pauseKey.publicKey)),
            pauseKey: pauseKey
        )

        // When / Then
        _ = try await TokenUnpauseTransaction()
            .tokenId(tokenId)
            .sign(pauseKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    internal func test_MissingTokenIdFails() async throws {
        // Given / When / Then
        await assertPrecheckStatus(
            try await TokenUnpauseTransaction().execute(testEnv.client),
            .invalidTokenID
        )
    }

    internal func test_MissingPauseKeySigFails() async throws {
        // Given
        let pauseKey = PrivateKey.generateEd25519()
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .treasuryAccountId(testEnv.operator.accountId)
                .pauseKey(.single(pauseKey.publicKey)),
            pauseKey: pauseKey
        )

        // When / Then
        await assertReceiptStatus(
            try await TokenUnpauseTransaction()
                .tokenId(tokenId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )
    }

    internal func test_MissingPauseKeyFails() async throws {
        // Given
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .treasuryAccountId(testEnv.operator.accountId)
        )

        // When / Then
        await assertReceiptStatus(
            try await TokenUnpauseTransaction()
                .tokenId(tokenId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .tokenHasNoPauseKey
        )
    }
}
