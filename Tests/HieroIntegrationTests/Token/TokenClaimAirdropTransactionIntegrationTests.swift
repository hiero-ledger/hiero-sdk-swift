// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal class TokenClaimAirdropTransactionIntegrationTests: HieroIntegrationTestCase {
    internal func test_ClaimTokens() async throws {
        // Given
        let accountKey = PrivateKey.generateEd25519()
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(accountKey.publicKey))
                .maxAutomaticTokenAssociations(TestConstants.testNoTokenAssociations),
            key: accountKey
        )

        let fungibleTokenAdminKey = PrivateKey.generateEd25519()
        let fungibleTokenSupplyKey = PrivateKey.generateEd25519()
        let fungibleTokenWipeKey = PrivateKey.generateEd25519()
        let fungibleTokenId = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .decimals(TestConstants.testTokenDecimals)
                .treasuryAccountId(testEnv.operator.accountId)
                .initialSupply(TestConstants.testFungibleInitialBalance)
                .adminKey(.single(fungibleTokenAdminKey.publicKey))
                .supplyKey(.single(fungibleTokenSupplyKey.publicKey))
                .wipeKey(.single(fungibleTokenWipeKey.publicKey))
                .sign(fungibleTokenAdminKey),
            adminKey: fungibleTokenAdminKey,
            supplyKey: fungibleTokenSupplyKey,
            wipeKey: fungibleTokenWipeKey
        )

        let nftAdminKey = PrivateKey.generateEd25519()
        let nftSupplyKey = PrivateKey.generateEd25519()
        let nftWipeKey = PrivateKey.generateEd25519()
        let nftTokenId = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .treasuryAccountId(testEnv.operator.accountId)
                .adminKey(.single(nftAdminKey.publicKey))
                .supplyKey(.single(nftSupplyKey.publicKey))
                .tokenType(.nonFungibleUnique)
                .wipeKey(.single(nftWipeKey.publicKey))
                .sign(nftAdminKey),
            adminKey: nftAdminKey,
            supplyKey: nftSupplyKey,
            wipeKey: nftWipeKey
        )

        let mintReceipt = try await TokenMintTransaction()
            .tokenId(nftTokenId)
            .metadata(TestConstants.testMetadata)
            .sign(nftSupplyKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let nftSerials = try XCTUnwrap(mintReceipt.serials)

        let record = try await TokenAirdropTransaction()
            .nftTransfer(nftTokenId.nft(nftSerials[0]), testEnv.operator.accountId, accountId)
            .nftTransfer(nftTokenId.nft(nftSerials[1]), testEnv.operator.accountId, accountId)
            .tokenTransfer(fungibleTokenId, accountId, TestConstants.testAmount)
            .tokenTransfer(fungibleTokenId, testEnv.operator.accountId, -TestConstants.testAmount)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        // When
        let tokenClaimRecord = try await TokenClaimAirdropTransaction()
            .addPendingAirdropId(record.pendingAirdropRecords[0].pendingAirdropId)
            .addPendingAirdropId(record.pendingAirdropRecords[1].pendingAirdropId)
            .addPendingAirdropId(record.pendingAirdropRecords[2].pendingAirdropId)
            .freezeWith(testEnv.client)
            .sign(accountKey)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        // Then
        XCTAssertEqual(tokenClaimRecord.pendingAirdropRecords.count, 0)

        let receiverAccountBalance = try await AccountBalanceQuery()
            .accountId(accountId)
            .execute(testEnv.client)

        XCTAssertEqual(receiverAccountBalance.tokenBalances[fungibleTokenId]!, UInt64(TestConstants.testAmount))
        XCTAssertEqual(receiverAccountBalance.tokenBalances[nftTokenId], 2)

        // Verify the operator does not hold the tokens
        let operatorBalance = try await AccountBalanceQuery()
            .accountId(testEnv.operator.accountId)
            .execute(testEnv.client)

        XCTAssertEqual(
            operatorBalance.tokenBalances[fungibleTokenId]!,
            TestConstants.testFungibleInitialBalance - UInt64(TestConstants.testAmount))
        XCTAssertEqual(operatorBalance.tokenBalances[nftTokenId]!, UInt64(TestConstants.testMintedNfts) - 2)
    }

    internal func test_ClaimTokensToMultipleReceivers() async throws {
        // Given
        let receiver1Key = PrivateKey.generateEd25519()
        let receiver1AccountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(receiver1Key.publicKey))
                .maxAutomaticTokenAssociations(TestConstants.testNoTokenAssociations),
            key: receiver1Key
        )

        let receiver2Key = PrivateKey.generateEd25519()
        let receiver2AccountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(receiver2Key.publicKey))
                .maxAutomaticTokenAssociations(TestConstants.testNoTokenAssociations),
            key: receiver2Key
        )

        let fungibleTokenAdminKey = PrivateKey.generateEd25519()
        let fungibleTokenSupplyKey = PrivateKey.generateEd25519()
        let fungibleTokenWipeKey = PrivateKey.generateEd25519()
        let fungibleTokenId = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .decimals(TestConstants.testTokenDecimals)
                .treasuryAccountId(testEnv.operator.accountId)
                .initialSupply(TestConstants.testFungibleInitialBalance)
                .adminKey(.single(fungibleTokenAdminKey.publicKey))
                .supplyKey(.single(fungibleTokenSupplyKey.publicKey))
                .wipeKey(.single(fungibleTokenWipeKey.publicKey))
                .sign(fungibleTokenAdminKey),
            adminKey: fungibleTokenAdminKey,
            supplyKey: fungibleTokenSupplyKey,
            wipeKey: fungibleTokenWipeKey
        )

        let nftAdminKey = PrivateKey.generateEd25519()
        let nftSupplyKey = PrivateKey.generateEd25519()
        let nftWipeKey = PrivateKey.generateEd25519()
        let nftTokenId = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .treasuryAccountId(testEnv.operator.accountId)
                .adminKey(.single(nftAdminKey.publicKey))
                .supplyKey(.single(nftSupplyKey.publicKey))
                .tokenType(.nonFungibleUnique)
                .wipeKey(.single(nftWipeKey.publicKey))
                .sign(nftAdminKey),
            adminKey: nftAdminKey,
            supplyKey: nftSupplyKey,
            wipeKey: nftWipeKey
        )

        let mintReceipt = try await TokenMintTransaction()
            .tokenId(nftTokenId)
            .metadata(TestConstants.testMetadata)
            .sign(nftSupplyKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let nftSerials = try XCTUnwrap(mintReceipt.serials)

        let record = try await TokenAirdropTransaction()
            .nftTransfer(nftTokenId.nft(nftSerials[0]), testEnv.operator.accountId, receiver1AccountId)
            .nftTransfer(nftTokenId.nft(nftSerials[1]), testEnv.operator.accountId, receiver1AccountId)
            .tokenTransfer(fungibleTokenId, receiver1AccountId, TestConstants.testAmount)
            .tokenTransfer(fungibleTokenId, testEnv.operator.accountId, -TestConstants.testAmount)
            .nftTransfer(nftTokenId.nft(nftSerials[2]), testEnv.operator.accountId, receiver2AccountId)
            .nftTransfer(nftTokenId.nft(nftSerials[3]), testEnv.operator.accountId, receiver2AccountId)
            .tokenTransfer(fungibleTokenId, receiver2AccountId, TestConstants.testAmount)
            .tokenTransfer(fungibleTokenId, testEnv.operator.accountId, -TestConstants.testAmount)
            .execute(testEnv.client)
            .getRecord(testEnv.client)
        let pendingAirdropIds = record.pendingAirdropRecords.map { $0.pendingAirdropId }

        // When
        let tokenClaimRecord = try await TokenClaimAirdropTransaction()
            .pendingAirdropIds(pendingAirdropIds)
            .freezeWith(testEnv.client)
            .sign(receiver1Key)
            .sign(receiver2Key)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        // Then
        XCTAssertEqual(tokenClaimRecord.pendingAirdropRecords.count, 0)

        let receiverAccount1Balance = try await AccountBalanceQuery()
            .accountId(receiver1AccountId)
            .execute(testEnv.client)

        XCTAssertEqual(receiverAccount1Balance.tokenBalances[fungibleTokenId]!, UInt64(TestConstants.testAmount))
        XCTAssertEqual(receiverAccount1Balance.tokenBalances[nftTokenId], 2)

        let receiverAccount2Balance = try await AccountBalanceQuery()
            .accountId(receiver2AccountId)
            .execute(testEnv.client)

        XCTAssertEqual(receiverAccount2Balance.tokenBalances[fungibleTokenId]!, UInt64(TestConstants.testAmount))
        XCTAssertEqual(receiverAccount2Balance.tokenBalances[nftTokenId], 2)

        let operatorBalance = try await AccountBalanceQuery()
            .accountId(testEnv.operator.accountId)
            .execute(testEnv.client)

        XCTAssertEqual(
            operatorBalance.tokenBalances[fungibleTokenId],
            TestConstants.testFungibleInitialBalance - UInt64(TestConstants.testAmount) * 2)
        XCTAssertEqual(operatorBalance.tokenBalances[nftTokenId], UInt64(TestConstants.testMintedNfts) - 4)
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

        let fungibleTokenAdminKey = PrivateKey.generateEd25519()
        let fungibleTokenSupplyKey = PrivateKey.generateEd25519()
        let fungibleTokenWipeKey = PrivateKey.generateEd25519()
        let fungibleTokenId = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .decimals(TestConstants.testTokenDecimals)
                .treasuryAccountId(testEnv.operator.accountId)
                .initialSupply(TestConstants.testFungibleInitialBalance)
                .adminKey(.single(fungibleTokenAdminKey.publicKey))
                .supplyKey(.single(fungibleTokenSupplyKey.publicKey))
                .wipeKey(.single(fungibleTokenWipeKey.publicKey))
                .sign(fungibleTokenAdminKey),
            adminKey: fungibleTokenAdminKey,
            supplyKey: fungibleTokenSupplyKey,
            wipeKey: fungibleTokenWipeKey
        )

        let nftAdminKey = PrivateKey.generateEd25519()
        let nftSupplyKey = PrivateKey.generateEd25519()
        let nftWipeKey = PrivateKey.generateEd25519()
        let nftTokenId = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .treasuryAccountId(testEnv.operator.accountId)
                .adminKey(.single(nftAdminKey.publicKey))
                .supplyKey(.single(nftSupplyKey.publicKey))
                .tokenType(.nonFungibleUnique)
                .wipeKey(.single(nftWipeKey.publicKey))
                .sign(nftAdminKey),
            adminKey: nftAdminKey,
            supplyKey: nftSupplyKey,
            wipeKey: nftWipeKey
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
        let tokenClaimRecord = try await TokenClaimAirdropTransaction()
            .pendingAirdropIds(pendingAirdropIds)
            .freezeWith(testEnv.client)
            .sign(accountKey)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        // Then
        XCTAssertEqual(tokenClaimRecord.pendingAirdropRecords.count, 0)

        let receiverAccountBalance = try await AccountBalanceQuery()
            .accountId(accountId)
            .execute(testEnv.client)

        XCTAssertEqual(receiverAccountBalance.tokenBalances[fungibleTokenId]!, UInt64(TestConstants.testAmount))
        XCTAssertEqual(receiverAccountBalance.tokenBalances[nftTokenId], 2)

        let operatorBalance = try await AccountBalanceQuery()
            .accountId(testEnv.operator.accountId)
            .execute(testEnv.client)

        XCTAssertEqual(
            operatorBalance.tokenBalances[fungibleTokenId],
            TestConstants.testFungibleInitialBalance - UInt64(TestConstants.testAmount))
        XCTAssertEqual(operatorBalance.tokenBalances[nftTokenId], UInt64(TestConstants.testMintedNfts) - 2)
    }

    internal func test_ClaimTokensForNonExistingAirdropFail() async throws {
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
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .decimals(TestConstants.testTokenDecimals)
                .treasuryAccountId(testEnv.operator.accountId)
                .initialSupply(TestConstants.testFungibleInitialBalance)
                .adminKey(.single(adminKey.publicKey))
                .supplyKey(.single(supplyKey.publicKey))
                .wipeKey(.single(wipeKey.publicKey))
                .sign(adminKey),
            adminKey: adminKey,
            supplyKey: supplyKey,
            wipeKey: wipeKey
        )

        let record = try await TokenAirdropTransaction()
            .tokenTransfer(tokenId, testEnv.operator.accountId, -TestConstants.testAmount)
            .tokenTransfer(tokenId, accountId, TestConstants.testAmount)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        // When / Then
        await assertReceiptStatus(
            try await TokenClaimAirdropTransaction()
                .addPendingAirdropId(record.pendingAirdropRecords[0].pendingAirdropId)
                .execute(testEnv.client)
                .getRecord(testEnv.client),
            .invalidSignature
        )
    }

    internal func test_ClaimAlreadyClaimedAirdropFail() async throws {
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
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .decimals(TestConstants.testTokenDecimals)
                .treasuryAccountId(testEnv.operator.accountId)
                .initialSupply(TestConstants.testFungibleInitialBalance)
                .adminKey(.single(adminKey.publicKey))
                .supplyKey(.single(supplyKey.publicKey))
                .wipeKey(.single(wipeKey.publicKey))
                .sign(adminKey),
            adminKey: adminKey,
            supplyKey: supplyKey,
            wipeKey: wipeKey
        )

        let record = try await TokenAirdropTransaction()
            .tokenTransfer(tokenId, testEnv.operator.accountId, -TestConstants.testAmount)
            .tokenTransfer(tokenId, accountId, TestConstants.testAmount)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        // When
        _ = try await TokenClaimAirdropTransaction()
            .addPendingAirdropId(record.pendingAirdropRecords[0].pendingAirdropId)
            .freezeWith(testEnv.client)
            .sign(accountKey)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        // Then
        await assertReceiptStatus(
            try await TokenClaimAirdropTransaction()
                .addPendingAirdropId(record.pendingAirdropRecords[0].pendingAirdropId)
                .freezeWith(testEnv.client)
                .sign(accountKey)
                .execute(testEnv.client)
                .getRecord(testEnv.client),
            .invalidPendingAirdropId
        )
    }

    internal func disabledTestClaimEmptyPendingAirdropFail() async throws {
        // Given / When / Then
        await assertThrowsHErrorAsync(
            try await TokenClaimAirdropTransaction()
                .execute(testEnv.client)
                .getRecord(testEnv.client),
            "expected error Claiming token"
        ) { error in
            guard case .transactionPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.transactionPreCheckStatus`")
                return
            }
            XCTAssertEqual(status, .emptyPendingAirdropIdList)
        }
    }

    internal func disabledTestClaimDuplicateEntriesFail() async throws {
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
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .decimals(TestConstants.testTokenDecimals)
                .treasuryAccountId(testEnv.operator.accountId)
                .initialSupply(TestConstants.testFungibleInitialBalance)
                .adminKey(.single(adminKey.publicKey))
                .supplyKey(.single(supplyKey.publicKey))
                .wipeKey(.single(wipeKey.publicKey))
                .sign(adminKey),
            adminKey: adminKey,
            supplyKey: supplyKey,
            wipeKey: wipeKey
        )

        let record = try await TokenAirdropTransaction()
            .tokenTransfer(tokenId, testEnv.operator.accountId, -TestConstants.testAmount)
            .tokenTransfer(tokenId, accountId, TestConstants.testAmount)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        // When / Then
        await assertThrowsHErrorAsync(
            try await TokenClaimAirdropTransaction()
                .addPendingAirdropId(record.pendingAirdropRecords[0].pendingAirdropId)
                .addPendingAirdropId(record.pendingAirdropRecords[0].pendingAirdropId)
                .execute(testEnv.client),
            "expected error Claiming token"
        ) { error in
            guard case .transactionPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.transactionPreCheckStatus`")
                return
            }
            XCTAssertEqual(status, .pendingAirdropIdRepeated)
        }
    }

    internal func test_ClaimDeletedTokensFail() async throws {
        // Given
        let accountKey = PrivateKey.generateEd25519()
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(accountKey.publicKey))
                .maxAutomaticTokenAssociations(TestConstants.testNoTokenAssociations),
            key: accountKey
        )

        let adminKey = PrivateKey.generateEd25519()
        let tokenId = try await createUnmanagedToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .decimals(TestConstants.testTokenDecimals)
                .treasuryAccountId(testEnv.operator.accountId)
                .initialSupply(TestConstants.testFungibleInitialBalance)
                .adminKey(.single(adminKey.publicKey))
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
        await assertReceiptStatus(
            try await TokenClaimAirdropTransaction()
                .addPendingAirdropId(record.pendingAirdropRecords[0].pendingAirdropId)
                .freezeWith(testEnv.client)
                .sign(accountKey)
                .execute(testEnv.client)
                .getRecord(testEnv.client),
            .tokenWasDeleted
        )
    }
}
