// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal class TokenMintTransactionIntegrationTests: HieroIntegrationTestCase {
    internal func test_Basic() async throws {
        // Given
        let (accountId, accountKey) = try await createTestAccount()
        let (tokenId, supplyKey) = try await createFungibleTokenWithSupplyKey(
            treasuryAccountId: accountId,
            treasuryKey: accountKey
        )

        // When
        let receipt = try await TokenMintTransaction()
            .tokenId(tokenId)
            .amount(TestConstants.testOperationAmount)
            .sign(supplyKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        XCTAssertEqual(receipt.totalSupply, TestConstants.testFungibleInitialBalance + 10)
    }

    internal func test_OverSupplyLimitFails() async throws {
        // Given
        let (accountId, accountKey) = try await createTestAccount()
        let supplyKey = PrivateKey.generateEd25519()
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .tokenSupplyType(.finite)
                .maxSupply(5)
                .treasuryAccountId(accountId)
                .supplyKey(.single(supplyKey.publicKey))
                .sign(accountKey),
            supplyKey: supplyKey
        )

        // When / Then
        await assertReceiptStatus(
            try await TokenMintTransaction()
                .tokenId(tokenId)
                .amount(6)
                .sign(supplyKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .tokenMaxSupplyReached
        )
    }

    internal func test_MissingTokenIdFails() async throws {
        // Given / When / Then
        await assertPrecheckStatus(
            try await TokenMintTransaction()
                .amount(6)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidTokenID
        )
    }

    internal func test_Zero() async throws {
        // Given
        let (accountId, accountKey) = try await createTestAccount()
        let (tokenId, supplyKey) = try await createFungibleTokenWithSupplyKey(
            treasuryAccountId: accountId,
            treasuryKey: accountKey
        )

        // When
        let receipt = try await TokenMintTransaction()
            .tokenId(tokenId)
            .amount(0)
            .sign(supplyKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        XCTAssertEqual(receipt.totalSupply, TestConstants.testFungibleInitialBalance)
    }

    internal func test_MissingSupplyKeySigFails() async throws {
        // Given
        let (accountId, accountKey) = try await createTestAccount()
        let supplyKey = PrivateKey.generateEd25519()
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .treasuryAccountId(accountId)
                .supplyKey(.single(supplyKey.publicKey))
                .sign(accountKey),
            supplyKey: supplyKey
        )

        // When / Then
        await assertReceiptStatus(
            try await TokenMintTransaction()
                .tokenId(tokenId)
                .amount(TestConstants.testOperationAmount)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )
    }

    internal func test_Nfts() async throws {
        // Given
        let (accountId, accountKey) = try await createTestAccount()
        let supplyKey = PrivateKey.generateEd25519()
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .treasuryAccountId(accountId)
                .supplyKey(.single(supplyKey.publicKey))
                .expirationTime(.now + .minutes(5))
                .tokenType(.nonFungibleUnique)
                .tokenSupplyType(.finite)
                .maxSupply(TestConstants.testMaxSupply)
                .sign(accountKey),
            supplyKey: supplyKey
        )

        // When
        let mintReceipt = try await TokenMintTransaction()
            .tokenId(tokenId)
            .metadata(TestConstants.testMetadata)
            .sign(supplyKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        let serials = try XCTUnwrap(mintReceipt.serials)
        XCTAssertEqual(serials.count, TestConstants.testMetadata.count)
    }

    internal func test_NftMetadataTooLongFails() async throws {
        // Given
        let (accountId, accountKey) = try await createTestAccount()
        let supplyKey = PrivateKey.generateEd25519()
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .treasuryAccountId(accountId)
                .supplyKey(.single(supplyKey.publicKey))
                .expirationTime(.now + .minutes(5))
                .tokenType(.nonFungibleUnique)
                .tokenSupplyType(.finite)
                .maxSupply(TestConstants.testMaxSupply)
                .sign(accountKey),
            supplyKey: supplyKey
        )

        // When / Then
        await assertReceiptStatus(
            try await TokenMintTransaction()
                .tokenId(tokenId)
                .metadata([Data(repeating: 1, count: 101)])
                .sign(supplyKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .metadataTooLong
        )
    }
}
