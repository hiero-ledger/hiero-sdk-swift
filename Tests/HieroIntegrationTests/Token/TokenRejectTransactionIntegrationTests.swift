// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal class TokenRejectTransactionIntegrationTests: HieroIntegrationTestCase {
    internal func test_BasicFtReject() async throws {
        // Given
        let accountKey = PrivateKey.generateEd25519()
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(accountKey.publicKey))
                .maxAutomaticTokenAssociations(TestConstants.testManyTokenAssociations),
            key: accountKey
        )

        let tokenId1 = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .decimals(TestConstants.testTokenDecimals)
                .initialSupply(TestConstants.testFungibleInitialBalance)
                .treasuryAccountId(testEnv.operator.accountId)
        )

        let tokenId2 = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .decimals(TestConstants.testTokenDecimals)
                .initialSupply(TestConstants.testFungibleInitialBalance)
                .treasuryAccountId(testEnv.operator.accountId)
        )

        _ = try await TransferTransaction()
            .tokenTransfer(tokenId1, testEnv.operator.accountId, -TestConstants.testTransferAmount)
            .tokenTransfer(tokenId1, accountId, TestConstants.testTransferAmount)
            .tokenTransfer(tokenId2, testEnv.operator.accountId, -TestConstants.testTransferAmount)
            .tokenTransfer(tokenId2, accountId, TestConstants.testTransferAmount)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // When
        _ = try await TokenRejectTransaction()
            .owner(accountId)
            .tokenIds([tokenId1, tokenId2])
            .freezeWith(testEnv.client)
            .sign(accountKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        let receiverBalance = try await AccountBalanceQuery()
            .accountId(accountId)
            .execute(testEnv.client)

        XCTAssertEqual(receiverBalance.tokenBalances[tokenId1], 0)
        XCTAssertEqual(receiverBalance.tokenBalances[tokenId2], 0)

        let treasuryAccountBalance = try await AccountBalanceQuery()
            .accountId(testEnv.operator.accountId)
            .execute(testEnv.client)

        XCTAssertEqual(treasuryAccountBalance.tokenBalances[tokenId1], TestConstants.testFungibleInitialBalance)
        XCTAssertEqual(treasuryAccountBalance.tokenBalances[tokenId2], TestConstants.testFungibleInitialBalance)
    }

    internal func test_BasicNftReject() async throws {
        // Given
        let accountKey = PrivateKey.generateEd25519()
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(accountKey.publicKey))
                .maxAutomaticTokenAssociations(TestConstants.testManyTokenAssociations),
            key: accountKey
        )

        let supplyKey1 = PrivateKey.generateEd25519()
        let tokenId1 = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .tokenType(.nonFungibleUnique)
                .treasuryAccountId(testEnv.operator.accountId)
                .supplyKey(.single(supplyKey1.publicKey)),
            supplyKey: supplyKey1
        )

        let supplyKey2 = PrivateKey.generateEd25519()
        let tokenId2 = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .tokenType(.nonFungibleUnique)
                .treasuryAccountId(testEnv.operator.accountId)
                .supplyKey(.single(supplyKey2.publicKey)),
            supplyKey: supplyKey2
        )

        let nftMintReceipt1 = try await TokenMintTransaction()
            .tokenId(tokenId1)
            .metadata(TestConstants.testMetadata)
            .sign(supplyKey1)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let nftSerials1 = try XCTUnwrap(nftMintReceipt1.serials)

        let nftMintReceipt2 = try await TokenMintTransaction()
            .tokenId(tokenId2)
            .metadata(TestConstants.testMetadata)
            .sign(supplyKey2)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let nftSerials = try XCTUnwrap(nftMintReceipt2.serials)

        _ = try await TransferTransaction()
            .nftTransfer(tokenId1.nft(nftSerials1[0]), testEnv.operator.accountId, accountId)
            .nftTransfer(tokenId1.nft(nftSerials1[1]), testEnv.operator.accountId, accountId)
            .nftTransfer(tokenId2.nft(nftSerials[0]), testEnv.operator.accountId, accountId)
            .nftTransfer(tokenId2.nft(nftSerials[1]), testEnv.operator.accountId, accountId)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // When
        _ = try await TokenRejectTransaction()
            .owner(accountId)
            .nftIds([tokenId1.nft(nftSerials1[1]), tokenId2.nft(nftSerials[1])])
            .freezeWith(testEnv.client)
            .sign(accountKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        let nft1Info = try await TokenNftInfoQuery()
            .nftId(tokenId1.nft(nftSerials1[1]))
            .execute(testEnv.client)

        XCTAssertEqual(nft1Info.accountId, testEnv.operator.accountId)

        let nft2Info = try await TokenNftInfoQuery()
            .nftId(tokenId2.nft(nftSerials[1]))
            .execute(testEnv.client)

        XCTAssertEqual(nft2Info.accountId, testEnv.operator.accountId)
    }

    internal func test_FtAndNftReject() async throws {
        // Given
        let accountKey = PrivateKey.generateEd25519()
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(accountKey.publicKey))
                .maxAutomaticTokenAssociations(TestConstants.testManyTokenAssociations),
            key: accountKey
        )

        let fungibleToken1Id = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .decimals(TestConstants.testTokenDecimals)
                .initialSupply(TestConstants.testFungibleInitialBalance)
                .treasuryAccountId(testEnv.operator.accountId)
        )

        let fungibleToken2Id = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .decimals(TestConstants.testTokenDecimals)
                .initialSupply(TestConstants.testFungibleInitialBalance)
                .treasuryAccountId(testEnv.operator.accountId)
        )

        let nftToken1SupplyKey = PrivateKey.generateEd25519()
        let nftToken1Id = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .tokenType(.nonFungibleUnique)
                .treasuryAccountId(testEnv.operator.accountId)
                .supplyKey(.single(nftToken1SupplyKey.publicKey)),
            supplyKey: nftToken1SupplyKey
        )

        let nftToken2SupplyKey = PrivateKey.generateEd25519()
        let nftToken2Id = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .tokenType(.nonFungibleUnique)
                .treasuryAccountId(testEnv.operator.accountId)
                .supplyKey(.single(nftToken2SupplyKey.publicKey)),
            supplyKey: nftToken2SupplyKey
        )

        let nftMintReceipt1 = try await TokenMintTransaction()
            .tokenId(nftToken1Id)
            .metadata(TestConstants.testMetadata)
            .sign(nftToken1SupplyKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let nftSerials1 = try XCTUnwrap(nftMintReceipt1.serials)

        let nftMintReceipt2 = try await TokenMintTransaction()
            .tokenId(nftToken2Id)
            .metadata(TestConstants.testMetadata)
            .sign(nftToken2SupplyKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let nftSerials = try XCTUnwrap(nftMintReceipt2.serials)

        _ = try await TransferTransaction()
            .tokenTransfer(fungibleToken1Id, testEnv.operator.accountId, -TestConstants.testTransferAmount)
            .tokenTransfer(fungibleToken1Id, accountId, TestConstants.testTransferAmount)
            .tokenTransfer(fungibleToken2Id, testEnv.operator.accountId, -TestConstants.testTransferAmount)
            .tokenTransfer(fungibleToken2Id, accountId, TestConstants.testTransferAmount)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await TransferTransaction()
            .nftTransfer(nftToken1Id.nft(nftSerials1[0]), testEnv.operator.accountId, accountId)
            .nftTransfer(nftToken1Id.nft(nftSerials1[1]), testEnv.operator.accountId, accountId)
            .nftTransfer(nftToken2Id.nft(nftSerials[0]), testEnv.operator.accountId, accountId)
            .nftTransfer(nftToken2Id.nft(nftSerials[1]), testEnv.operator.accountId, accountId)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // When
        _ = try await TokenRejectTransaction()
            .owner(accountId)
            .tokenIds([fungibleToken1Id, fungibleToken2Id])
            .nftIds([nftToken1Id.nft(nftSerials1[1]), nftToken2Id.nft(nftSerials[1])])
            .freezeWith(testEnv.client)
            .sign(accountKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        let receiverAccountBalance = try await AccountBalanceQuery()
            .accountId(accountId)
            .execute(testEnv.client)

        XCTAssertEqual(receiverAccountBalance.tokenBalances[fungibleToken1Id], 0)
        XCTAssertEqual(receiverAccountBalance.tokenBalances[fungibleToken2Id], 0)
        XCTAssertEqual(receiverAccountBalance.tokenBalances[nftToken1Id], 1)
        XCTAssertEqual(receiverAccountBalance.tokenBalances[nftToken2Id], 1)

        let treasuryAccountBalance = try await AccountBalanceQuery()
            .accountId(testEnv.operator.accountId)
            .execute(testEnv.client)

        XCTAssertEqual(treasuryAccountBalance.tokenBalances[fungibleToken1Id], TestConstants.testFungibleInitialBalance)
        XCTAssertEqual(treasuryAccountBalance.tokenBalances[fungibleToken2Id], TestConstants.testFungibleInitialBalance)

        let nft1Info = try await TokenNftInfoQuery()
            .nftId(nftToken1Id.nft(nftSerials1[1]))
            .execute(testEnv.client)

        XCTAssertEqual(nft1Info.accountId, testEnv.operator.accountId)

        let nft2Info = try await TokenNftInfoQuery()
            .nftId(nftToken2Id.nft(nftSerials[1]))
            .execute(testEnv.client)

        XCTAssertEqual(nft2Info.accountId, testEnv.operator.accountId)
    }

    internal func test_FtAndNftPaused() async throws {
        // Given
        let accountKey = PrivateKey.generateEd25519()
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(accountKey.publicKey))
                .maxAutomaticTokenAssociations(TestConstants.testManyTokenAssociations),
            key: accountKey
        )

        let fungibleTokenPauseKey = PrivateKey.generateEd25519()
        let fungibleTokenId = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .decimals(TestConstants.testTokenDecimals)
                .initialSupply(TestConstants.testFungibleInitialBalance)
                .treasuryAccountId(testEnv.operator.accountId)
                .pauseKey(.single(fungibleTokenPauseKey.publicKey)),
            pauseKey: fungibleTokenPauseKey
        )

        let nftTokenSupplyKey = PrivateKey.generateEd25519()
        let nftTokenPauseKey = PrivateKey.generateEd25519()
        let nftTokenId = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .tokenType(.nonFungibleUnique)
                .treasuryAccountId(testEnv.operator.accountId)
                .supplyKey(.single(nftTokenSupplyKey.publicKey))
                .pauseKey(.single(nftTokenPauseKey.publicKey)),
            supplyKey: nftTokenSupplyKey,
            pauseKey: nftTokenPauseKey
        )

        let nftMintReceipt = try await TokenMintTransaction()
            .tokenId(nftTokenId)
            .metadata(TestConstants.testMetadata)
            .sign(nftTokenSupplyKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let nftSerials = try XCTUnwrap(nftMintReceipt.serials)

        _ = try await TransferTransaction()
            .tokenTransfer(fungibleTokenId, testEnv.operator.accountId, -TestConstants.testTransferAmount)
            .tokenTransfer(fungibleTokenId, accountId, TestConstants.testTransferAmount)
            .nftTransfer(nftTokenId.nft(nftSerials[0]), testEnv.operator.accountId, accountId)
            .nftTransfer(nftTokenId.nft(nftSerials[1]), testEnv.operator.accountId, accountId)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await TokenPauseTransaction()
            .tokenId(fungibleTokenId)
            .sign(fungibleTokenPauseKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await TokenPauseTransaction()
            .tokenId(nftTokenId)
            .sign(nftTokenPauseKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // When / Then
        await assertReceiptStatus(
            try await TokenRejectTransaction()
                .owner(accountId)
                .addTokenId(fungibleTokenId)
                .nftIds([nftTokenId.nft(nftSerials[1])])
                .freezeWith(testEnv.client)
                .sign(accountKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .tokenIsPaused
        )
    }

    internal func test_AddOrSetNftTokenIdFail() async throws {
        // Given
        let accountKey = PrivateKey.generateEd25519()
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(accountKey.publicKey))
                .maxAutomaticTokenAssociations(TestConstants.testManyTokenAssociations),
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

        _ = try await TransferTransaction()
            .nftTransfer(tokenId.nft(nftSerials[0]), testEnv.operator.accountId, accountId)
            .nftTransfer(tokenId.nft(nftSerials[1]), testEnv.operator.accountId, accountId)
            .nftTransfer(tokenId.nft(nftSerials[2]), testEnv.operator.accountId, accountId)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // When / Then
        await assertReceiptStatus(
            try await TokenRejectTransaction()
                .owner(accountId)
                .addTokenId(tokenId)
                .nftIds([tokenId.nft(nftSerials[1]), tokenId.nft(nftSerials[2])])
                .freezeWith(testEnv.client)
                .sign(accountKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .accountAmountTransfersOnlyAllowedForFungibleCommon
        )

        await assertReceiptStatus(
            try await TokenRejectTransaction()
                .owner(accountId)
                .tokenIds([tokenId])
                .freezeWith(testEnv.client)
                .sign(accountKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .accountAmountTransfersOnlyAllowedForFungibleCommon
        )
    }

    internal func test_TreasuryFail() async throws {
        // Given
        let fungibleTokenId = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .decimals(TestConstants.testTokenDecimals)
                .initialSupply(TestConstants.testFungibleInitialBalance)
                .treasuryAccountId(testEnv.operator.accountId)
        )

        let nftTokenSupplyKey = PrivateKey.generateEd25519()
        let nftTokenId = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .tokenType(.nonFungibleUnique)
                .treasuryAccountId(testEnv.operator.accountId)
                .supplyKey(.single(nftTokenSupplyKey.publicKey)),
            supplyKey: nftTokenSupplyKey
        )

        let nftMintReceipt = try await TokenMintTransaction()
            .tokenId(nftTokenId)
            .metadata(TestConstants.testMetadata)
            .sign(nftTokenSupplyKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let nftSerials = try XCTUnwrap(nftMintReceipt.serials)

        // When / Then
        await assertReceiptStatus(
            try await TokenRejectTransaction()
                .owner(testEnv.operator.accountId)
                .addTokenId(fungibleTokenId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .accountIsTreasury
        )

        await assertReceiptStatus(
            try await TokenRejectTransaction()
                .owner(testEnv.operator.accountId)
                .addNftId(nftTokenId.nft(nftSerials[0]))
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .accountIsTreasury
        )
    }

    internal func test_InvalidSigFail() async throws {
        // Given
        let accountKey = PrivateKey.generateEd25519()
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(accountKey.publicKey))
                .maxAutomaticTokenAssociations(TestConstants.testManyTokenAssociations),
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

        let randomKey = PrivateKey.generateEd25519()

        _ = try await TransferTransaction()
            .tokenTransfer(tokenId, testEnv.operator.accountId, -TestConstants.testTransferAmount)
            .tokenTransfer(tokenId, accountId, TestConstants.testTransferAmount)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // When / Then
        await assertReceiptStatus(
            try await TokenRejectTransaction()
                .owner(accountId)
                .addTokenId(tokenId)
                .freezeWith(testEnv.client)
                .sign(randomKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )
    }

    internal func test_MissingTokenFail() async throws {
        // Given / When / Then
        await assertPrecheckStatus(
            try await TokenRejectTransaction()
                .owner(testEnv.operator.accountId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .emptyTokenReferenceList
        )
    }

    internal func test_TokenReferenceListSizeExceededFail() async throws {
        // Given
        let accountKey = PrivateKey.generateEd25519()
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(accountKey.publicKey))
                .maxAutomaticTokenAssociations(TestConstants.testManyTokenAssociations),
            key: accountKey
        )

        let fungibleTokenId = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .decimals(TestConstants.testTokenDecimals)
                .initialSupply(TestConstants.testFungibleInitialBalance)
                .treasuryAccountId(testEnv.operator.accountId)
        )

        let nftTokenSupplyKey = PrivateKey.generateEd25519()
        let nftTokenId = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .tokenType(.nonFungibleUnique)
                .treasuryAccountId(testEnv.operator.accountId)
                .supplyKey(.single(nftTokenSupplyKey.publicKey)),
            supplyKey: nftTokenSupplyKey
        )

        let nftMintReceipt = try await TokenMintTransaction()
            .tokenId(nftTokenId)
            .metadata(TestConstants.testMetadata)
            .sign(nftTokenSupplyKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let nftSerials = try XCTUnwrap(nftMintReceipt.serials)

        _ = try await TransferTransaction()
            .tokenTransfer(fungibleTokenId, testEnv.operator.accountId, -TestConstants.testTransferAmount)
            .tokenTransfer(fungibleTokenId, accountId, TestConstants.testTransferAmount)
            .nftTransfer(nftTokenId.nft(nftSerials[0]), testEnv.operator.accountId, accountId)
            .nftTransfer(nftTokenId.nft(nftSerials[1]), testEnv.operator.accountId, accountId)
            .nftTransfer(nftTokenId.nft(nftSerials[2]), testEnv.operator.accountId, accountId)
            .nftTransfer(nftTokenId.nft(nftSerials[3]), testEnv.operator.accountId, accountId)
            .nftTransfer(nftTokenId.nft(nftSerials[4]), testEnv.operator.accountId, accountId)
            .nftTransfer(nftTokenId.nft(nftSerials[5]), testEnv.operator.accountId, accountId)
            .nftTransfer(nftTokenId.nft(nftSerials[6]), testEnv.operator.accountId, accountId)
            .nftTransfer(nftTokenId.nft(nftSerials[7]), testEnv.operator.accountId, accountId)
            .nftTransfer(nftTokenId.nft(nftSerials[8]), testEnv.operator.accountId, accountId)
            .nftTransfer(nftTokenId.nft(nftSerials[9]), testEnv.operator.accountId, accountId)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // When / Then
        await assertReceiptStatus(
            try await TokenRejectTransaction()
                .owner(accountId)
                .addTokenId(fungibleTokenId)
                .nftIds([
                    nftTokenId.nft(nftSerials[0]),
                    nftTokenId.nft(nftSerials[1]),
                    nftTokenId.nft(nftSerials[2]),
                    nftTokenId.nft(nftSerials[3]),
                    nftTokenId.nft(nftSerials[4]),
                    nftTokenId.nft(nftSerials[5]),
                    nftTokenId.nft(nftSerials[6]),
                    nftTokenId.nft(nftSerials[7]),
                    nftTokenId.nft(nftSerials[8]),
                    nftTokenId.nft(nftSerials[9]),
                ])
                .freezeWith(testEnv.client)
                .sign(accountKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .tokenReferenceListSizeLimitExceeded
        )
    }
}
