// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal class TokenPauseTransactionIntegrationTests: HieroIntegrationTestCase {
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
        _ = try await TokenPauseTransaction()
            .tokenId(tokenId)
            .sign(pauseKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    internal func test_MissingTokenIdFails() async throws {
        // Given / When / Then
        await assertPrecheckStatus(
            try await TokenPauseTransaction()
                .execute(testEnv.client),
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
                .pauseKey(.single(pauseKey.publicKey))
        )

        // When / Then
        await assertReceiptStatus(
            try await TokenPauseTransaction()
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
            try await TokenPauseTransaction()
                .tokenId(tokenId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .tokenHasNoPauseKey
        )
    }
}
