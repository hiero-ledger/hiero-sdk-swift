// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal class TokenBurnTransactionIntegrationTests: HieroIntegrationTestCase {
    internal func test_Basic() async throws {
        // Given
        let (accountId, accountKey) = try await createTestAccount()
        let (tokenId, supplyKey) = try await createFungibleTokenWithSupplyKey(
            treasuryAccountId: accountId,
            treasuryKey: accountKey,
            initialSupply: TestConstants.testSmallInitialSupply
        )

        // When
        let receipt = try await TokenBurnTransaction()
            .tokenId(tokenId)
            .amount(TestConstants.testOperationAmount)
            .sign(supplyKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        XCTAssertEqual(receipt.totalSupply, 0)
    }

    internal func test_MissingTokenIdFails() async throws {
        // Given / When / Then
        await assertPrecheckStatus(
            try await TokenBurnTransaction()
                .amount(TestConstants.testOperationAmount)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidTokenID
        )
    }

    internal func test_BurnZero() async throws {
        // Given
        let (accountId, accountKey) = try await createTestAccount()
        let (tokenId, supplyKey) = try await createFungibleTokenWithSupplyKey(
            treasuryAccountId: accountId,
            treasuryKey: accountKey,
            initialSupply: 0
        )

        // When
        let receipt = try await TokenBurnTransaction()
            .tokenId(tokenId)
            .amount(0)
            .sign(supplyKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        XCTAssertEqual(receipt.totalSupply, 0)
    }

    internal func test_MissingSupplyKeySigFails() async throws {
        // Given
        let (accountId, accountKey) = try await createTestAccount()
        let (tokenId, supplyKey) = try await createFungibleTokenWithSupplyKey(
            treasuryAccountId: accountId,
            treasuryKey: accountKey,
            initialSupply: 0
        )
        _ = supplyKey  // Intentionally not using the supply key

        // When / Then
        await assertReceiptStatus(
            try await TokenBurnTransaction()
                .tokenId(tokenId)
                .amount(0)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )
    }

    internal func test_BurnNfts() async throws {
        // Given
        let (accountId, accountKey) = try await createTestAccount()
        let (tokenId, supplyKey) = try await createNftWithSupplyKey(
            treasuryAccountId: accountId,
            treasuryKey: accountKey
        )

        let receipt = try await TokenMintTransaction()
            .tokenId(tokenId)
            .metadata(TestConstants.testMetadata)
            .sign(supplyKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let serials = try XCTUnwrap(receipt.serials)

        // When / Then
        _ = try await TokenBurnTransaction()
            .tokenId(tokenId)
            .setSerials(serials)
            .sign(supplyKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    internal func test_UnownedNftFails() async throws {
        // Given
        let alice = try await createTestAccount()
        let bob = try await createTestAccount()
        let (tokenId, supplyKey) = try await createNftWithSupplyKey(
            treasuryAccountId: alice.accountId,
            treasuryKey: alice.key
        )

        let receipt = try await TokenMintTransaction()
            .tokenId(tokenId)
            .metadata(TestConstants.testMetadata)
            .sign(supplyKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let serials = try XCTUnwrap(receipt.serials)

        try await associateToken(tokenId, with: bob.accountId, key: bob.key)

        _ = try await TransferTransaction()
            .nftTransfer(NftId(tokenId: tokenId, serial: serials[0]), alice.accountId, bob.accountId)
            .sign(alice.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // When / Then
        await assertReceiptStatus(
            try await TokenBurnTransaction()
                .tokenId(tokenId)
                .setSerials(serials)
                .sign(supplyKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .treasuryMustOwnBurnedNft
        )
    }
}
