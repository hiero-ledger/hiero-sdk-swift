// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal class TokenAirdropTransactionIntegrationTests: HieroIntegrationTestCase {
    internal func test_AirdropAssociatedTokens() async throws {
        // Given
        let accountKey = PrivateKey.generateEd25519()
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(accountKey.publicKey))
                .maxAutomaticTokenAssociations(TestConstants.testUnlimitedTokenAssociations),
            key: accountKey
        )

        let fungibleTokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .decimals(TestConstants.testTokenDecimals)
                .treasuryAccountId(testEnv.operator.accountId)
                .initialSupply(TestConstants.testFungibleInitialBalance)
        )

        let nftSupplyKey = PrivateKey.generateEd25519()
        let nftTokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
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

        // When
        _ = try await TokenAirdropTransaction()
            .nftTransfer(nftTokenId.nft(nftSerials[0]), testEnv.operator.accountId, accountId)
            .nftTransfer(nftTokenId.nft(nftSerials[1]), testEnv.operator.accountId, accountId)
            .tokenTransfer(fungibleTokenId, accountId, TestConstants.testAmount)
            .tokenTransfer(fungibleTokenId, testEnv.operator.accountId, -TestConstants.testAmount)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        let accountBalance = try await AccountBalanceQuery()
            .accountId(accountId)
            .execute(testEnv.client)

        XCTAssertEqual(accountBalance.tokenBalances[fungibleTokenId]!, UInt64(TestConstants.testAmount))
        XCTAssertEqual(accountBalance.tokenBalances[nftTokenId], 2)

        let operatorBalance = try await AccountBalanceQuery()
            .accountId(testEnv.operator.accountId)
            .execute(testEnv.client)
        XCTAssertEqual(
            operatorBalance.tokenBalances[fungibleTokenId]!,
            TestConstants.testFungibleInitialBalance - UInt64(TestConstants.testAmount))
        XCTAssertEqual(operatorBalance.tokenBalances[nftTokenId]!, UInt64(TestConstants.testMintedNfts) - 2)
    }

    internal func test_AirdropNonAssociatedTokens() async throws {
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
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .decimals(TestConstants.testTokenDecimals)
                .treasuryAccountId(testEnv.operator.accountId)
                .initialSupply(TestConstants.testFungibleInitialBalance)
        )

        let nftSupplyKey = PrivateKey.generateEd25519()
        let nftTokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
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

        // When
        var tx = try await TokenAirdropTransaction()
            .nftTransfer(nftTokenId.nft(nftSerials[0]), testEnv.operator.accountId, accountId)
            .nftTransfer(nftTokenId.nft(nftSerials[1]), testEnv.operator.accountId, accountId)
            .tokenTransfer(fungibleTokenId, accountId, TestConstants.testAmount)
            .tokenTransfer(fungibleTokenId, testEnv.operator.accountId, -TestConstants.testAmount)
            .execute(testEnv.client)

        // Then
        _ = try await tx.validateStatus(true).getReceipt(testEnv.client)
        let record = try await tx.getRecord(testEnv.client)

        XCTAssertNotNil(record.pendingAirdropRecords)
        XCTAssertFalse(record.pendingAirdropRecords.isEmpty)

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

    internal func test_AirdropToAlias() async throws {
        // Given
        let aliasKey = PrivateKey.generateEd25519()
        let aliasAccountId = aliasKey.publicKey.toAccountId(shard: 0, realm: 0)

        let fungibleTokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .decimals(TestConstants.testTokenDecimals)
                .treasuryAccountId(testEnv.operator.accountId)
                .initialSupply(TestConstants.testFungibleInitialBalance)
        )

        let nftSupplyKey = PrivateKey.generateEd25519()
        let nftTokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
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

        // When
        _ = try await TokenAirdropTransaction()
            .nftTransfer(nftTokenId.nft(nftSerials[0]), testEnv.operator.accountId, aliasAccountId)
            .nftTransfer(nftTokenId.nft(nftSerials[1]), testEnv.operator.accountId, aliasAccountId)
            .tokenTransfer(fungibleTokenId, aliasAccountId, TestConstants.testAmount)
            .tokenTransfer(fungibleTokenId, testEnv.operator.accountId, -TestConstants.testAmount)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        let accountInfo = try await AccountInfoQuery()
            .accountId(aliasAccountId)
            .execute(testEnv.client)
        await registerAccount(accountInfo.accountId, key: aliasKey)

        let receiverAccountBalance = try await AccountBalanceQuery()
            .accountId(aliasAccountId)
            .execute(testEnv.client)

        XCTAssertEqual(receiverAccountBalance.tokenBalances[fungibleTokenId]!, UInt64(TestConstants.testAmount))
        XCTAssertEqual(receiverAccountBalance.tokenBalances[nftTokenId], 2)

        let operatorBalance = try await AccountBalanceQuery()
            .accountId(testEnv.operator.accountId)
            .execute(testEnv.client)

        XCTAssertEqual(
            operatorBalance.tokenBalances[fungibleTokenId]!,
            TestConstants.testFungibleInitialBalance - UInt64(TestConstants.testAmount))
        XCTAssertEqual(operatorBalance.tokenBalances[nftTokenId]!, UInt64(TestConstants.testMintedNfts) - 2)
    }

    internal func test_AirdropWithCustomFees() async throws {
        // Given
        let senderKey = PrivateKey.generateEd25519()
        let senderAccountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(senderKey.publicKey))
                .maxAutomaticTokenAssociations(TestConstants.testUnlimitedTokenAssociations),
            key: senderKey
        )

        let receiverKey = PrivateKey.generateEd25519()
        let receiverAccountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(receiverKey.publicKey))
                .maxAutomaticTokenAssociations(TestConstants.testUnlimitedTokenAssociations),
            key: receiverKey
        )

        let customFeeTokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .decimals(TestConstants.testTokenDecimals)
                .treasuryAccountId(testEnv.operator.accountId)
                .initialSupply(TestConstants.testFungibleInitialBalance)
                .maxSupply(TestConstants.testFungibleInitialBalance)
                .tokenSupplyType(TokenSupplyType.finite)
        )

        let fee = AnyCustomFee.fixed(
            FixedFee.init(
                amount: 1,
                denominatingTokenId: customFeeTokenId,
                feeCollectorAccountId: testEnv.operator.accountId,
                allCollectorsAreExempt: true
            )
        )

        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name("Test Token")
                .symbol("TST")
                .decimals(TestConstants.testTokenDecimals)
                .initialSupply(TestConstants.testFungibleInitialBalance)
                .maxSupply(TestConstants.testFungibleInitialBalance)
                .treasuryAccountId(testEnv.operator.accountId)
                .tokenSupplyType(TokenSupplyType.finite)
                .customFees([fee])
        )

        _ = try await TransferTransaction()
            .tokenTransfer(tokenId, testEnv.operator.accountId, -TestConstants.testAmount)
            .tokenTransfer(tokenId, senderAccountId, TestConstants.testAmount)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await TransferTransaction()
            .tokenTransfer(customFeeTokenId, testEnv.operator.accountId, -TestConstants.testAmount)
            .tokenTransfer(customFeeTokenId, senderAccountId, TestConstants.testAmount)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // When
        _ = try await TokenAirdropTransaction()
            .tokenTransfer(tokenId, receiverAccountId, TestConstants.testAmount)
            .tokenTransfer(tokenId, senderAccountId, -TestConstants.testAmount)
            .freezeWith(testEnv.client)
            .sign(senderKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        let receiverAccountBalance = try await AccountBalanceQuery()
            .accountId(receiverAccountId)
            .execute(testEnv.client)

        XCTAssertEqual(receiverAccountBalance.tokenBalances[tokenId]!, UInt64(TestConstants.testAmount))

        let senderAccountBalance = try await AccountBalanceQuery()
            .accountId(senderAccountId)
            .execute(testEnv.client)

        XCTAssertEqual(senderAccountBalance.tokenBalances[tokenId]!, 0)
        XCTAssertEqual(senderAccountBalance.tokenBalances[customFeeTokenId]!, UInt64(TestConstants.testAmount) - 1)

        let operatorBalance = try await AccountBalanceQuery()
            .accountId(testEnv.operator.accountId)
            .execute(testEnv.client)

        XCTAssertEqual(
            operatorBalance.tokenBalances[customFeeTokenId]!,
            TestConstants.testFungibleInitialBalance - UInt64(TestConstants.testAmount) + 1)
        XCTAssertEqual(
            operatorBalance.tokenBalances[tokenId]!,
            TestConstants.testFungibleInitialBalance - UInt64(TestConstants.testAmount))
    }

    internal func test_AirdropTokensWithReceiverSigRequiredFungible() async throws {
        // Given
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name("Test Token")
                .symbol("TST")
                .decimals(TestConstants.testTokenDecimals)
                .initialSupply(TestConstants.testFungibleInitialBalance)
                .maxSupply(TestConstants.testFungibleInitialBalance)
                .treasuryAccountId(testEnv.operator.accountId)
                .tokenSupplyType(TokenSupplyType.finite)
        )

        let accountKey = PrivateKey.generateEd25519()
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(accountKey.publicKey))
                .initialBalance(TestConstants.testSmallHbarBalance)
                .receiverSignatureRequired(true)
                .maxAutomaticTokenAssociations(TestConstants.testUnlimitedTokenAssociations)
                .freezeWith(testEnv.client)
                .sign(accountKey),
            key: accountKey
        )

        // When / Then
        _ = try await TokenAirdropTransaction()
            .tokenTransfer(tokenId, testEnv.operator.accountId, -TestConstants.testAmount)
            .tokenTransfer(tokenId, accountId, TestConstants.testAmount)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    internal func test_AirdropTokensWithReceiverSigRequiredNft() async throws {
        // Given
        let accountKey = PrivateKey.generateEd25519()
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(accountKey.publicKey))
                .initialBalance(TestConstants.testSmallHbarBalance)
                .receiverSignatureRequired(true)
                .maxAutomaticTokenAssociations(TestConstants.testUnlimitedTokenAssociations)
                .sign(accountKey),
            key: accountKey
        )

        let supplyKey = PrivateKey.generateEd25519()
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name("Test NFT")
                .symbol("TST")
                .treasuryAccountId(testEnv.operator.accountId)
                .tokenType(.nonFungibleUnique)
                .supplyKey(.single(supplyKey.publicKey)),
            supplyKey: supplyKey
        )

        let mintReceipt = try await TokenMintTransaction()
            .tokenId(tokenId)
            .metadata(TestConstants.testMetadata)
            .sign(supplyKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let nftSerials = try XCTUnwrap(mintReceipt.serials)

        // When / Then
        _ = try await TokenAirdropTransaction()
            .nftTransfer(tokenId.nft(nftSerials[0]), testEnv.operator.accountId, accountId)
            .nftTransfer(tokenId.nft(nftSerials[1]), testEnv.operator.accountId, accountId)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    internal func test_AirdropAllowanceAndWithoutBalanceFungibleFail() async throws {
        // Given
        let spenderKey = PrivateKey.generateEd25519()
        let spenderAccountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(spenderKey.publicKey))
                .maxAutomaticTokenAssociations(TestConstants.testUnlimitedTokenAssociations),
            key: spenderKey
        )

        let senderKey = PrivateKey.generateEd25519()
        let senderAccountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(senderKey.publicKey))
                .maxAutomaticTokenAssociations(TestConstants.testUnlimitedTokenAssociations),
            key: senderKey
        )

        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name("Test Token")
                .symbol("TST")
                .decimals(TestConstants.testTokenDecimals)
                .initialSupply(TestConstants.testFungibleInitialBalance)
                .maxSupply(TestConstants.testFungibleInitialBalance)
                .treasuryAccountId(testEnv.operator.accountId)
                .tokenSupplyType(TokenSupplyType.finite)
        )

        _ = try await TransferTransaction()
            .tokenTransfer(tokenId, testEnv.operator.accountId, -TestConstants.testAmount)
            .tokenTransfer(tokenId, senderAccountId, TestConstants.testAmount)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await AccountAllowanceApproveTransaction()
            .approveTokenAllowance(tokenId, senderAccountId, spenderAccountId, UInt64(TestConstants.testAmount))
            .freezeWith(testEnv.client)
            .sign(senderKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // When / Then
        await assertPrecheckStatus(
            try await TokenAirdropTransaction()
                .tokenTransfer(tokenId, spenderAccountId, TestConstants.testAmount)
                .approvedTokenTransfer(tokenId, spenderAccountId, -TestConstants.testAmount)
                .transactionId(TransactionId.generateFrom(spenderAccountId))
                .freezeWith(testEnv.client)
                .sign(spenderKey)
                .execute(testEnv.client),
            .notSupported
        )
    }

    internal func test_AirdropAllowanceAndWithoutBalanceNftFail() async throws {
        // Given
        let spenderKey = PrivateKey.generateEd25519()
        let spenderAccountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(spenderKey.publicKey))
                .maxAutomaticTokenAssociations(TestConstants.testUnlimitedTokenAssociations),
            key: spenderKey
        )

        let senderKey = PrivateKey.generateEd25519()
        let senderAccountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(senderKey.publicKey))
                .maxAutomaticTokenAssociations(TestConstants.testUnlimitedTokenAssociations),
            key: senderKey
        )

        let supplyKey = PrivateKey.generateEd25519()
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name("Test NFT")
                .symbol("TST")
                .treasuryAccountId(testEnv.operator.accountId)
                .tokenType(.nonFungibleUnique)
                .supplyKey(.single(supplyKey.publicKey)),
            supplyKey: supplyKey
        )

        let mintReceipt = try await TokenMintTransaction()
            .tokenId(tokenId)
            .metadata(TestConstants.testMetadata)
            .sign(supplyKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let nftSerials = try XCTUnwrap(mintReceipt.serials)

        _ = try await TransferTransaction()
            .nftTransfer(tokenId.nft(nftSerials[0]), testEnv.operator.accountId, senderAccountId)
            .nftTransfer(tokenId.nft(nftSerials[1]), testEnv.operator.accountId, senderAccountId)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await AccountAllowanceApproveTransaction()
            .approveTokenNftAllowance(tokenId.nft(nftSerials[0]), senderAccountId, spenderAccountId)
            .approveTokenNftAllowance(tokenId.nft(nftSerials[1]), senderAccountId, spenderAccountId)
            .freezeWith(testEnv.client)
            .sign(senderKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // When / Then
        await assertPrecheckStatus(
            try await TokenAirdropTransaction()
                .approvedNftTransfer(tokenId.nft(nftSerials[0]), spenderAccountId, spenderAccountId)
                .approvedNftTransfer(tokenId.nft(nftSerials[1]), spenderAccountId, spenderAccountId)
                .transactionId(TransactionId.generateFrom(spenderAccountId))
                .freezeWith(testEnv.client)
                .sign(spenderKey)
                .execute(testEnv.client),
            .notSupported
        )
    }

    internal func disabledTestAirdropTokensWithInvalidBodyFail() async throws {
        // Given
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name("Test Token")
                .symbol("TST")
                .decimals(TestConstants.testTokenDecimals)
                .initialSupply(TestConstants.testFungibleInitialBalance)
                .maxSupply(TestConstants.testFungibleInitialBalance)
                .treasuryAccountId(testEnv.operator.accountId)
                .tokenSupplyType(TokenSupplyType.finite)
        )

        // When / Then
        await assertThrowsHErrorAsync(
            try await TokenAirdropTransaction()
                .execute(testEnv.client),
            "expected error Airdropping token"
        ) { error in
            guard case .transactionPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.transactionPreCheckStatus`")
                return
            }
            XCTAssertEqual(status, .emptyTokenTransferBody)
        }

        await assertThrowsHErrorAsync(
            try await TokenAirdropTransaction()
                .tokenTransfer(tokenId, testEnv.operator.accountId, TestConstants.testAmount)
                .tokenTransfer(tokenId, testEnv.operator.accountId, TestConstants.testAmount)
                .execute(testEnv.client),
            "expected error Airdropping token"
        ) { error in
            guard case .transactionPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.transactionPreCheckStatus`")
                return
            }
            XCTAssertEqual(status, .invalidTransactionBody)
        }
    }
}
