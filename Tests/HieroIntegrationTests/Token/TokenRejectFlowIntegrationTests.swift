// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal final class TokenRejectFlowIntegrationTests: HieroIntegrationTestCase {
    internal func test_BasicFlowFungible() async throws {
        // Given
        let accountKey = PrivateKey.generateEd25519()
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(accountKey.publicKey))
                .maxAutomaticTokenAssociations(TestConstants.testNoTokenAssociations),
            key: accountKey
        )

        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .decimals(TestConstants.testTokenDecimals)
                .initialSupply(TestConstants.testFungibleInitialBalance)
                .treasuryAccountId(testEnv.operator.accountId)
        )

        _ = try await TokenAssociateTransaction()
            .accountId(accountId)
            .tokenIds([tokenId])
            .freezeWith(testEnv.client)
            .sign(accountKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await TransferTransaction()
            .tokenTransfer(tokenId, testEnv.operator.accountId, -TestConstants.testTransferAmount)
            .tokenTransfer(tokenId, accountId, TestConstants.testTransferAmount)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // When
        _ = try await TokenRejectFlow()
            .ownerId(accountId)
            .addTokenId(tokenId)
            .freezeWith(testEnv.client)
            .sign(accountKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        let treasuryAccountBalance = try await AccountBalanceQuery()
            .accountId(testEnv.operator.accountId)
            .execute(testEnv.client)

        XCTAssertEqual(treasuryAccountBalance.tokenBalances[tokenId], TestConstants.testFungibleInitialBalance)

        await assertReceiptStatus(
            try await TransferTransaction()
                .tokenTransfer(tokenId, testEnv.operator.accountId, -TestConstants.testTransferAmount)
                .tokenTransfer(tokenId, accountId, TestConstants.testTransferAmount)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .tokenNotAssociatedToAccount
        )
    }

    internal func test_BasicFlowNft() async throws {
        // Given
        let accountKey = PrivateKey.generateEd25519()
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(accountKey.publicKey))
                .maxAutomaticTokenAssociations(TestConstants.testNoTokenAssociations),
            key: accountKey
        )

        let supplyKey = PrivateKey.generateEd25519()
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .tokenType(.nonFungibleUnique)
                .treasuryAccountId(testEnv.operator.accountId)
                .supplyKey(.single(supplyKey.publicKey)),
            supplyKey: supplyKey
        )

        let nftMintReceipt = try await TokenMintTransaction()
            .tokenId(tokenId)
            .metadata(TestConstants.testMetadata)
            .sign(supplyKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let nftSerials = try XCTUnwrap(nftMintReceipt.serials)

        _ = try await TokenAssociateTransaction()
            .accountId(accountId)
            .tokenIds([tokenId])
            .freezeWith(testEnv.client)
            .sign(accountKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await TransferTransaction()
            .nftTransfer(tokenId.nft(nftSerials[0]), testEnv.operator.accountId, accountId)
            .nftTransfer(tokenId.nft(nftSerials[1]), testEnv.operator.accountId, accountId)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // When
        _ = try await TokenRejectFlow()
            .ownerId(accountId)
            .nftIds([tokenId.nft(nftSerials[0]), tokenId.nft(nftSerials[1])])
            .freezeWith(testEnv.client)
            .sign(accountKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        let nftTokenIdNftInfo = try await TokenNftInfoQuery()
            .nftId(tokenId.nft(nftSerials[1]))
            .execute(testEnv.client)

        XCTAssertEqual(nftTokenIdNftInfo.accountId, testEnv.operator.accountId)

        await assertReceiptStatus(
            try await TransferTransaction()
                .nftTransfer(tokenId.nft(nftSerials[1]), testEnv.operator.accountId, accountId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .tokenNotAssociatedToAccount
        )
    }

    internal func test_RejectFlowForPartiallyOwnedNfts() async throws {
        // Given
        let accountKey = PrivateKey.generateEd25519()
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(accountKey.publicKey))
                .maxAutomaticTokenAssociations(TestConstants.testNoTokenAssociations),
            key: accountKey
        )

        let supplyKey = PrivateKey.generateEd25519()
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .tokenType(.nonFungibleUnique)
                .treasuryAccountId(testEnv.operator.accountId)
                .supplyKey(.single(supplyKey.publicKey)),
            supplyKey: supplyKey
        )

        let nftMintReceipt = try await TokenMintTransaction()
            .tokenId(tokenId)
            .metadata(TestConstants.testMetadata)
            .sign(supplyKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let nftSerials = try XCTUnwrap(nftMintReceipt.serials)

        _ = try await TokenAssociateTransaction()
            .accountId(accountId)
            .tokenIds([tokenId])
            .freezeWith(testEnv.client)
            .sign(accountKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await TransferTransaction()
            .nftTransfer(tokenId.nft(nftSerials[0]), testEnv.operator.accountId, accountId)
            .nftTransfer(tokenId.nft(nftSerials[1]), testEnv.operator.accountId, accountId)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // When / Then
        await assertReceiptStatus(
            try await TokenRejectFlow()
                .ownerId(accountId)
                .addNftId(tokenId.nft(nftSerials[1]))
                .freezeWith(testEnv.client)
                .sign(accountKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .accountStillOwnsNfts
        )
    }
}
