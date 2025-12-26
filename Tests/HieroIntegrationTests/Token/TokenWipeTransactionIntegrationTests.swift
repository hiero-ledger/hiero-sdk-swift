// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal final class TokenWipeTransactionIntegrationTests: HieroIntegrationTestCase {
    internal func test_Fungible() async throws {
        // Given
        let alice = try await createTestAccount()
        let bob = try await createTestAccount()

        let wipeKey = PrivateKey.generateEd25519()
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .treasuryAccountId(alice.accountId)
                .wipeKey(.single(wipeKey.publicKey))
                .initialSupply(TestConstants.testSmallInitialSupply)
                .sign(alice.key),
            wipeKey: wipeKey
        )

        try await associateToken(tokenId, with: bob.accountId, key: bob.key)

        _ = try await TransferTransaction()
            .tokenTransfer(tokenId, alice.accountId, -TestConstants.testTransferAmount)
            .tokenTransfer(tokenId, bob.accountId, TestConstants.testTransferAmount)
            .sign(alice.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // When / Then
        _ = try await TokenWipeTransaction()
            .accountId(bob.accountId)
            .tokenId(tokenId)
            .amount(TestConstants.testOperationAmount)
            .sign(wipeKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    internal func test_Nft() async throws {
        // Given
        let alice = try await createTestAccount()
        let bob = try await createTestAccount()

        let supplyKey = PrivateKey.generateEd25519()
        let wipeKey = PrivateKey.generateEd25519()
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .treasuryAccountId(alice.accountId)
                .supplyKey(.single(supplyKey.publicKey))
                .wipeKey(.single(wipeKey.publicKey))
                .expirationTime(.now + .minutes(5))
                .tokenType(.nonFungibleUnique)
                .sign(alice.key),
            supplyKey: supplyKey,
            wipeKey: wipeKey
        )

        try await associateToken(tokenId, with: bob.accountId, key: bob.key)

        let receipt = try await TokenMintTransaction()
            .tokenId(tokenId)
            .metadata(TestConstants.testMetadata)
            .sign(supplyKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let serials = try XCTUnwrap(receipt.serials)

        let transferTx = TransferTransaction()

        for serial in serials {
            transferTx.nftTransfer(NftId(tokenId: tokenId, serial: serial), alice.accountId, bob.accountId)
        }

        _ = try await transferTx.sign(alice.key).execute(testEnv.client).getReceipt(testEnv.client)

        // When / Then
        _ = try await TokenWipeTransaction()
            .tokenId(tokenId)
            .serials(serials)
            .accountId(bob.accountId)
            .sign(wipeKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    internal func test_UnownedNftFails() async throws {
        // Given
        let alice = try await createTestAccount()
        let bob = try await createTestAccount()

        let supplyKey = PrivateKey.generateEd25519()
        let wipeKey = PrivateKey.generateEd25519()
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .treasuryAccountId(alice.accountId)
                .supplyKey(.single(supplyKey.publicKey))
                .wipeKey(.single(wipeKey.publicKey))
                .expirationTime(.now + .minutes(5))
                .tokenType(.nonFungibleUnique)
                .sign(alice.key),
            supplyKey: supplyKey,
            wipeKey: wipeKey
        )

        try await associateToken(tokenId, with: bob.accountId, key: bob.key)

        let receipt = try await TokenMintTransaction()
            .tokenId(tokenId)
            .metadata(TestConstants.testMetadata)
            .sign(supplyKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let serials = try XCTUnwrap(receipt.serials)

        // When / Then
        await assertReceiptStatus(
            try await TokenWipeTransaction()
                .tokenId(tokenId)
                .serials(serials)
                .accountId(bob.accountId)
                .sign(wipeKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .accountDoesNotOwnWipedNft
        )
    }

    internal func test_MissingAccountIdFails() async throws {
        // Given
        let (accountId, accountKey) = try await createTestAccount()

        let wipeKey = PrivateKey.generateEd25519()
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .treasuryAccountId(accountId)
                .wipeKey(.single(wipeKey.publicKey))
                .sign(accountKey),
            wipeKey: wipeKey
        )

        // When / Then
        await assertPrecheckStatus(
            try await TokenWipeTransaction()
                .tokenId(tokenId)
                .amount(TestConstants.testOperationAmount)
                .sign(wipeKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidAccountID
        )
    }

    internal func test_MissingTokenIdFails() async throws {
        // Given / When / Then
        await assertPrecheckStatus(
            try await TokenWipeTransaction()
                .amount(TestConstants.testOperationAmount)
                .accountId(testEnv.operator.accountId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidTokenID
        )
    }

    internal func test_MissingAmount() async throws {
        // Given
        let alice = try await createTestAccount()
        let bob = try await createTestAccount()

        let wipeKey = PrivateKey.generateEd25519()
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .treasuryAccountId(alice.accountId)
                .initialSupply(TestConstants.testSmallInitialSupply)
                .wipeKey(.single(wipeKey.publicKey))
                .sign(alice.key),
            wipeKey: wipeKey
        )

        try await associateToken(tokenId, with: bob.accountId, key: bob.key)

        _ = try await TransferTransaction()
            .tokenTransfer(tokenId, alice.accountId, -TestConstants.testTransferAmount)
            .tokenTransfer(tokenId, bob.accountId, TestConstants.testTransferAmount)
            .sign(alice.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // When / Then
        _ = try await TokenWipeTransaction()
            .tokenId(tokenId)
            .accountId(bob.accountId)
            .sign(wipeKey)
            .execute(testEnv.client)
    }
}
