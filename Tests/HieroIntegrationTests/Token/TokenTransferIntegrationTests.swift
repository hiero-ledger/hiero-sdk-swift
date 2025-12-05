// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal final class TokenTransferIntegrationTests: HieroIntegrationTestCase {
    internal func test_Basic() async throws {
        // Given
        let alice = try await createTestAccount()
        let bob = try await createTestAccount()
        let tokenId = try await createBasicFungibleToken(
            treasuryAccountId: alice.accountId,
            treasuryKey: alice.key
        )
        try await associateToken(tokenId, with: bob.accountId, key: bob.key)

        // When
        _ = try await TransferTransaction()
            .tokenTransfer(tokenId, alice.accountId, -TestConstants.testTransferAmount)
            .tokenTransfer(tokenId, bob.accountId, TestConstants.testTransferAmount)
            .sign(alice.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        _ = try await TransferTransaction()
            .tokenTransfer(tokenId, bob.accountId, -TestConstants.testTransferAmount)
            .tokenTransfer(tokenId, alice.accountId, TestConstants.testTransferAmount)
            .sign(bob.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    internal func test_InsufficientBalanceForFeeFails() async throws {
        // Given
        let (aliceId, aliceKey) = try await createTestAccount()
        let (bobId, bobKey) = try await createTestAccount()
        let (carolId, carolKey) = try await createTestAccount()

        let fee = FixedFee(
            amount: 5_000_000_000,
            denominatingTokenId: 0,
            feeCollectorAccountId: aliceId,
            allCollectorsAreExempt: true
        )

        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .initialSupply(1)
                .treasuryAccountId(aliceId)
                .freezeDefault(false)
                .expirationTime(.now + .minutes(5))
                .customFees([.fixed(fee)])
                .sign(aliceKey)
        )

        try await associateToken(tokenId, with: bobId, key: bobKey)
        try await associateToken(tokenId, with: carolId, key: carolKey)

        _ = try await TransferTransaction()
            .tokenTransfer(tokenId, aliceId, -1)
            .tokenTransfer(tokenId, bobId, 1)
            .sign(aliceKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // When / Then
        await assertReceiptStatus(
            try await TransferTransaction()
                .tokenTransfer(tokenId, bobId, -1)
                .tokenTransfer(tokenId, carolId, 1)
                .sign(bobKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .insufficientSenderAccountBalanceForCustomFee
        )
    }

    internal func test_UnownedTokenFails() async throws {
        // Given
        let alice = try await createTestAccount()
        let bob = try await createTestAccount()
        let tokenId = try await createBasicFungibleToken(
            treasuryAccountId: alice.accountId,
            treasuryKey: alice.key
        )
        try await associateToken(tokenId, with: bob.accountId, key: bob.key)

        // When / Then
        await assertReceiptStatus(
            try await TransferTransaction()
                .tokenTransfer(tokenId, bob.accountId, -TestConstants.testTransferAmount)
                .tokenTransfer(tokenId, alice.accountId, TestConstants.testTransferAmount)
                .sign(bob.key)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .insufficientTokenBalance
        )
    }

    internal func test_Decimals() async throws {
        // Given
        let alice = try await createTestAccount()
        let bob = try await createTestAccount()
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .initialSupply(TestConstants.testSmallInitialSupply)
                .decimals(TestConstants.testTokenDecimals)
                .treasuryAccountId(alice.accountId)
                .sign(alice.key)
        )
        try await associateToken(tokenId, with: bob.accountId, key: bob.key)

        // When
        _ = try await TransferTransaction()
            .tokenTransferWithDecimals(tokenId, alice.accountId, -10, 3)
            .tokenTransferWithDecimals(tokenId, bob.accountId, 10, 3)
            .sign(alice.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        _ = try await TransferTransaction()
            .tokenTransferWithDecimals(tokenId, bob.accountId, -10, 3)
            .tokenTransferWithDecimals(tokenId, alice.accountId, 10, 3)
            .sign(bob.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    internal func test_IncorrectDecimalsFails() async throws {
        // Given
        let alice = try await createTestAccount()
        let bob = try await createTestAccount()
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .initialSupply(TestConstants.testSmallInitialSupply)
                .decimals(TestConstants.testTokenDecimals)
                .treasuryAccountId(alice.accountId)
                .sign(alice.key)
        )
        try await associateToken(tokenId, with: bob.accountId, key: bob.key)

        // When / Then
        await assertReceiptStatus(
            try await TransferTransaction()
                .tokenTransferWithDecimals(tokenId, alice.accountId, -10, 2)
                .tokenTransferWithDecimals(tokenId, bob.accountId, 10, 2)
                .sign(alice.key)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .unexpectedTokenDecimals
        )
    }
}
