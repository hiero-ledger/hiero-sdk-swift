// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal class TokenCancelAirdropTransactionIntegrationTests: HieroIntegrationTestCase {
    internal func test_CancelTokens() async throws {
        // Given
        let accountKey = PrivateKey.generateEd25519()
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(accountKey.publicKey))
                .maxAutomaticTokenAssociations(TestConstants.testNoTokenAssociations),
            key: accountKey
        )

        let fungibleTokenId = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .decimals(TestConstants.testTokenDecimals)
                .treasuryAccountId(testEnv.operator.accountId)
                .initialSupply(TestConstants.testFungibleInitialBalance)
        )

        let nftSupplyKey = PrivateKey.generateEd25519()
        let nftTokenId = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .treasuryAccountId(testEnv.operator.accountId)
                .supplyKey(.single(nftSupplyKey.publicKey))
                .tokenType(.nonFungibleUnique),
            supplyKey: nftSupplyKey
        )

        let mintReceipt = try await TokenMintTransaction()
            .tokenId(nftTokenId)
            .metadata(TestConstants.testMetadata)
            .sign(nftSupplyKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let nftSerials = try XCTUnwrap(mintReceipt.serials)

        var record = try await TokenAirdropTransaction()
            .nftTransfer(nftTokenId.nft(nftSerials[0]), testEnv.operator.accountId, accountId)
            .nftTransfer(nftTokenId.nft(nftSerials[1]), testEnv.operator.accountId, accountId)
            .tokenTransfer(fungibleTokenId, accountId, TestConstants.testAmount)
            .tokenTransfer(fungibleTokenId, testEnv.operator.accountId, -TestConstants.testAmount)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        // When
        record = try await TokenCancelAirdropTransaction()
            .addPendingAirdropId(record.pendingAirdropRecords[0].pendingAirdropId)
            .addPendingAirdropId(record.pendingAirdropRecords[1].pendingAirdropId)
            .addPendingAirdropId(record.pendingAirdropRecords[2].pendingAirdropId)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        // Then
        XCTAssertEqual(record.pendingAirdropRecords.count, 0)

        let accountBalance = try await AccountBalanceQuery()
            .accountId(accountId)
            .execute(testEnv.client)

        XCTAssertNil(accountBalance.tokenBalances[fungibleTokenId])
        XCTAssertNil(accountBalance.tokenBalances[nftTokenId])

        let operatorBalance = try await AccountBalanceQuery()
            .accountId(testEnv.operator.accountId)
            .execute(testEnv.client)

        XCTAssertEqual(operatorBalance.tokenBalances[fungibleTokenId]!, TestConstants.testFungibleInitialBalance)
        XCTAssertEqual(operatorBalance.tokenBalances[nftTokenId]!, UInt64(TestConstants.testMintedNfts))
    }

    internal func test_CancelTokensWhenFrozen() async throws {
        // Given
        let accountKey = PrivateKey.generateEd25519()
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(accountKey.publicKey))
                .maxAutomaticTokenAssociations(TestConstants.testNoTokenAssociations),
            key: accountKey
        )

        let freezeKey = PrivateKey.generateEd25519()
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .decimals(TestConstants.testTokenDecimals)
                .treasuryAccountId(testEnv.operator.accountId)
                .initialSupply(TestConstants.testFungibleInitialBalance)
                .freezeKey(.single(freezeKey.publicKey))
        )

        let record = try await TokenAirdropTransaction()
            .tokenTransfer(tokenId, accountId, TestConstants.testAmount)
            .tokenTransfer(tokenId, testEnv.operator.accountId, -TestConstants.testAmount)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        _ = try await TokenAssociateTransaction()
            .accountId(accountId)
            .tokenIds([tokenId])
            .freezeWith(testEnv.client)
            .sign(accountKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await TokenFreezeTransaction()
            .tokenId(tokenId)
            .accountId(accountId)
            .freezeWith(testEnv.client)
            .sign(freezeKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // When / Then
        _ = try await TokenCancelAirdropTransaction()
            .addPendingAirdropId(record.pendingAirdropRecords[0].pendingAirdropId)
            .execute(testEnv.client)
            .getRecord(testEnv.client)
    }

    internal func test_CancelTokensWhenPaused() async throws {
        // Given
        let accountKey = PrivateKey.generateEd25519()
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(accountKey.publicKey))
                .maxAutomaticTokenAssociations(TestConstants.testNoTokenAssociations),
            key: accountKey
        )

        let pauseKey = PrivateKey.generateEd25519()
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .decimals(TestConstants.testTokenDecimals)
                .treasuryAccountId(testEnv.operator.accountId)
                .initialSupply(TestConstants.testFungibleInitialBalance)
                .pauseKey(.single(pauseKey.publicKey)),
            pauseKey: pauseKey
        )

        let record = try await TokenAirdropTransaction()
            .tokenTransfer(tokenId, accountId, TestConstants.testAmount)
            .tokenTransfer(tokenId, testEnv.operator.accountId, -TestConstants.testAmount)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        _ = try await TokenPauseTransaction()
            .tokenId(tokenId)
            .sign(pauseKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // When / Then
        _ = try await TokenCancelAirdropTransaction()
            .addPendingAirdropId(record.pendingAirdropRecords[0].pendingAirdropId)
            .execute(testEnv.client)
            .getRecord(testEnv.client)
    }

    internal func test_CancelTokensWhenTokenIsDeleted() async throws {
        // Given
        let accountKey = PrivateKey.generateEd25519()
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(accountKey.publicKey))
                .maxAutomaticTokenAssociations(TestConstants.testNoTokenAssociations),
            key: accountKey
        )

        let adminKey = PrivateKey.generateEd25519()
        let supplyKey = PrivateKey.generateEd25519()
        let wipeKey = PrivateKey.generateEd25519()
        let tokenId = try await createUnmanagedToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .decimals(TestConstants.testTokenDecimals)
                .treasuryAccountId(testEnv.operator.accountId)
                .initialSupply(TestConstants.testFungibleInitialBalance)
                .adminKey(.single(adminKey.publicKey))
                .supplyKey(.single(supplyKey.publicKey))
                .wipeKey(.single(wipeKey.publicKey))
                .sign(adminKey)
        )

        let record = try await TokenAirdropTransaction()
            .tokenTransfer(tokenId, accountId, TestConstants.testAmount)
            .tokenTransfer(tokenId, testEnv.operator.accountId, -TestConstants.testAmount)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        _ = try await TokenDeleteTransaction()
            .tokenId(tokenId)
            .sign(adminKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // When / Then
        _ = try await TokenCancelAirdropTransaction()
            .addPendingAirdropId(record.pendingAirdropRecords[0].pendingAirdropId)
            .execute(testEnv.client)
            .getRecord(testEnv.client)
    }

    internal func test_CancelTokensToMultipleReceivers() async throws {
        // Given
        let receiverKey1 = PrivateKey.generateEd25519()
        let receiverAccount1Id = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(receiverKey1.publicKey))
                .maxAutomaticTokenAssociations(TestConstants.testNoTokenAssociations),
            key: receiverKey1
        )

        let receiverKey2 = PrivateKey.generateEd25519()
        let receiverAccount2Id = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(receiverKey2.publicKey))
                .maxAutomaticTokenAssociations(TestConstants.testNoTokenAssociations),
            key: receiverKey2
        )

        let fungibleTokenId = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .decimals(TestConstants.testTokenDecimals)
                .treasuryAccountId(testEnv.operator.accountId)
                .initialSupply(TestConstants.testFungibleInitialBalance)
        )

        let nftSupplyKey = PrivateKey.generateEd25519()
        let nftTokenId = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .treasuryAccountId(testEnv.operator.accountId)
                .supplyKey(.single(nftSupplyKey.publicKey))
                .tokenType(.nonFungibleUnique),
            supplyKey: nftSupplyKey
        )

        let mintReceipt = try await TokenMintTransaction()
            .tokenId(nftTokenId)
            .metadata(TestConstants.testMetadata)
            .sign(nftSupplyKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let nftSerials = try XCTUnwrap(mintReceipt.serials)

        let record = try await TokenAirdropTransaction()
            .nftTransfer(nftTokenId.nft(nftSerials[0]), testEnv.operator.accountId, receiverAccount1Id)
            .nftTransfer(nftTokenId.nft(nftSerials[1]), testEnv.operator.accountId, receiverAccount1Id)
            .tokenTransfer(fungibleTokenId, receiverAccount1Id, TestConstants.testAmount)
            .tokenTransfer(fungibleTokenId, testEnv.operator.accountId, -TestConstants.testAmount)
            .nftTransfer(nftTokenId.nft(nftSerials[2]), testEnv.operator.accountId, receiverAccount2Id)
            .nftTransfer(nftTokenId.nft(nftSerials[3]), testEnv.operator.accountId, receiverAccount2Id)
            .tokenTransfer(fungibleTokenId, receiverAccount2Id, TestConstants.testAmount)
            .tokenTransfer(fungibleTokenId, testEnv.operator.accountId, -TestConstants.testAmount)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        let pendingAirdropIds = record.pendingAirdropRecords.map { $0.pendingAirdropId }

        // When
        let tokenCancelRecord = try await TokenCancelAirdropTransaction()
            .pendingAirdropIds(pendingAirdropIds)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        // Then
        XCTAssertEqual(tokenCancelRecord.pendingAirdropRecords.count, 0)

        let receiverAccount1Balance = try await AccountBalanceQuery()
            .accountId(receiverAccount1Id)
            .execute(testEnv.client)

        XCTAssertNil(receiverAccount1Balance.tokenBalances[fungibleTokenId])
        XCTAssertNil(receiverAccount1Balance.tokenBalances[nftTokenId])

        let receiverAccount2Balance = try await AccountBalanceQuery()
            .accountId(receiverAccount2Id)
            .execute(testEnv.client)

        XCTAssertNil(receiverAccount2Balance.tokenBalances[fungibleTokenId])
        XCTAssertNil(receiverAccount2Balance.tokenBalances[nftTokenId])

        let operatorBalance = try await AccountBalanceQuery()
            .accountId(testEnv.operator.accountId)
            .execute(testEnv.client)

        XCTAssertEqual(operatorBalance.tokenBalances[fungibleTokenId], TestConstants.testFungibleInitialBalance)
        XCTAssertEqual(operatorBalance.tokenBalances[nftTokenId], UInt64(TestConstants.testMintedNfts))
    }

    internal func test_ClaimTokensToMultipleAirdropTxns() async throws {
        // Given
        let accountKey = PrivateKey.generateEd25519()
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(accountKey.publicKey))
                .maxAutomaticTokenAssociations(TestConstants.testNoTokenAssociations),
            key: accountKey
        )

        let fungibleTokenId = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .decimals(TestConstants.testTokenDecimals)
                .treasuryAccountId(testEnv.operator.accountId)
                .initialSupply(TestConstants.testFungibleInitialBalance)
        )

        let nftSupplyKey = PrivateKey.generateEd25519()
        let nftTokenId = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .treasuryAccountId(testEnv.operator.accountId)
                .supplyKey(.single(nftSupplyKey.publicKey))
                .tokenType(.nonFungibleUnique),
            supplyKey: nftSupplyKey
        )

        let mintReceipt = try await TokenMintTransaction()
            .tokenId(nftTokenId)
            .metadata(TestConstants.testMetadata)
            .sign(nftSupplyKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let nftSerials = try XCTUnwrap(mintReceipt.serials)

        let record1 = try await TokenAirdropTransaction()
            .nftTransfer(nftTokenId.nft(nftSerials[0]), testEnv.operator.accountId, accountId)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        let record2 = try await TokenAirdropTransaction()
            .nftTransfer(nftTokenId.nft(nftSerials[1]), testEnv.operator.accountId, accountId)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        let record3 = try await TokenAirdropTransaction()
            .tokenTransfer(fungibleTokenId, accountId, TestConstants.testAmount)
            .tokenTransfer(fungibleTokenId, testEnv.operator.accountId, -TestConstants.testAmount)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        let pendingAirdropIds: [PendingAirdropId] = [
            record1.pendingAirdropRecords[0].pendingAirdropId,
            record2.pendingAirdropRecords[0].pendingAirdropId,
            record3.pendingAirdropRecords[0].pendingAirdropId,
        ]

        // When
        let tokenCancelRecord = try await TokenCancelAirdropTransaction()
            .pendingAirdropIds(pendingAirdropIds)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        // Then
        XCTAssertEqual(tokenCancelRecord.pendingAirdropRecords.count, 0)

        let accountBalance = try await AccountBalanceQuery()
            .accountId(accountId)
            .execute(testEnv.client)

        XCTAssertNil(accountBalance.tokenBalances[fungibleTokenId])
        XCTAssertNil(accountBalance.tokenBalances[nftTokenId])

        let operatorBalance = try await AccountBalanceQuery()
            .accountId(testEnv.operator.accountId)
            .execute(testEnv.client)

        XCTAssertEqual(operatorBalance.tokenBalances[fungibleTokenId], TestConstants.testFungibleInitialBalance)
        XCTAssertEqual(operatorBalance.tokenBalances[nftTokenId], UInt64(TestConstants.testMintedNfts))
    }

    internal func test_CancelTokensForNonExistingAirdropFail() async throws {
        // Given
        let accountKey = PrivateKey.generateEd25519()
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(accountKey.publicKey))
                .maxAutomaticTokenAssociations(TestConstants.testNoTokenAssociations),
            key: accountKey
        )

        let randomKey = PrivateKey.generateEd25519()
        let randomAccountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(randomKey.publicKey))
                .maxAutomaticTokenAssociations(TestConstants.testNoTokenAssociations),
            key: randomKey
        )

        let fungibleTokenId = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .decimals(TestConstants.testTokenDecimals)
                .treasuryAccountId(testEnv.operator.accountId)
                .initialSupply(TestConstants.testFungibleInitialBalance)
        )

        let record = try await TokenAirdropTransaction()
            .tokenTransfer(fungibleTokenId, accountId, TestConstants.testAmount)
            .tokenTransfer(fungibleTokenId, testEnv.operator.accountId, -TestConstants.testAmount)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        // When / Then
        await assertPrecheckStatus(
            try await TokenCancelAirdropTransaction()
                .transactionId(TransactionId.generateFrom(randomAccountId))
                .addPendingAirdropId(record.pendingAirdropRecords[0].pendingAirdropId)
                .execute(testEnv.client)
                .getRecord(testEnv.client),
            .invalidSignature
        )
    }

    internal func test_CancelCancelledAirdropFail() async throws {
        // Given
        let accountKey = PrivateKey.generateEd25519()
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(accountKey.publicKey))
                .maxAutomaticTokenAssociations(TestConstants.testNoTokenAssociations),
            key: accountKey
        )

        let fungibleTokenId = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .decimals(TestConstants.testTokenDecimals)
                .treasuryAccountId(testEnv.operator.accountId)
                .initialSupply(TestConstants.testFungibleInitialBalance)
        )

        let record = try await TokenAirdropTransaction()
            .tokenTransfer(fungibleTokenId, accountId, TestConstants.testAmount)
            .tokenTransfer(fungibleTokenId, testEnv.operator.accountId, -TestConstants.testAmount)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        // When
        _ = try await TokenCancelAirdropTransaction()
            .addPendingAirdropId(record.pendingAirdropRecords[0].pendingAirdropId)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        // Then
        await assertReceiptStatus(
            try await TokenCancelAirdropTransaction()
                .addPendingAirdropId(record.pendingAirdropRecords[0].pendingAirdropId)
                .execute(testEnv.client)
                .getRecord(testEnv.client),
            .invalidPendingAirdropId
        )
    }

    internal func test_CancelEmptyPendingAirdropFail() async throws {
        // Given / When / Then
        await assertPrecheckStatus(
            try await TokenCancelAirdropTransaction()
                .execute(testEnv.client),
            .emptyPendingAirdropIdList
        )
    }

    internal func test_CancelDuplicateEntriesFail() async throws {
        // Given
        let accountKey = PrivateKey.generateEd25519()
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(accountKey.publicKey))
                .maxAutomaticTokenAssociations(TestConstants.testNoTokenAssociations),
            key: accountKey
        )

        let fungibleTokenId = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .decimals(TestConstants.testTokenDecimals)
                .treasuryAccountId(testEnv.operator.accountId)
                .initialSupply(TestConstants.testFungibleInitialBalance)
        )

        let record = try await TokenAirdropTransaction()
            .tokenTransfer(fungibleTokenId, accountId, TestConstants.testAmount)
            .tokenTransfer(fungibleTokenId, testEnv.operator.accountId, -TestConstants.testAmount)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        // When / Then
        await assertPrecheckStatus(
            try await TokenCancelAirdropTransaction()
                .addPendingAirdropId(record.pendingAirdropRecords[0].pendingAirdropId)
                .addPendingAirdropId(record.pendingAirdropRecords[0].pendingAirdropId)
                .execute(testEnv.client),
            .pendingAirdropIdRepeated
        )
    }
}
