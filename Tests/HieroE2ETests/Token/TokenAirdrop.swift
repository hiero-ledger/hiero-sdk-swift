/*
 * ‌
 * Hedera Swift SDK
 * ​
 * Copyright (C) 2022 - 2024 Hedera Hashgraph, LLC
 * ​
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ‍
 */

import Hiero
import XCTest

internal class TokenAirdrop: XCTestCase {
    internal func testAirdropAssociatedTokens() async throws {
        let testEnv = try TestEnvironment.nonFree

        // Create a receiver account with unlimited auto associations
        let receiverKey = PrivateKey.generateEd25519()
        let receiverAccount = try await Account.create(testEnv, Key.single(receiverKey.publicKey), -1)

        // Create a token and an NFT
        let token = try await FungibleToken.create(testEnv, decimals: 3)
        let nft = try await Nft.create(testEnv)

        // Mint NFTs
        let mintReceipt = try await TokenMintTransaction()
            .tokenId(nft.id)
            .metadata(testMetadata)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let nftSerials = try XCTUnwrap(mintReceipt.serials)

        // Airdrop tokens
        _ = try await TokenAirdropTransaction()
            .nftTransfer(nft.id.nft(nftSerials[0]), testEnv.operator.accountId, receiverAccount.id)
            .nftTransfer(nft.id.nft(nftSerials[1]), testEnv.operator.accountId, receiverAccount.id)
            .tokenTransfer(token.id, receiverAccount.id, testAmount)
            .tokenTransfer(token.id, testEnv.operator.accountId, -testAmount)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Verify the receiver holds the tokens via query
        let receiverAccountBalance = try await AccountBalanceQuery()
            .accountId(receiverAccount.id)
            .execute(testEnv.client)

        XCTAssertEqual(receiverAccountBalance.tokenBalances[token.id]!, UInt64(testAmount))
        XCTAssertEqual(receiverAccountBalance.tokenBalances[nft.id], 2)

        // Verify the operator does not hold the tokens
        let operatorBalance = try await AccountBalanceQuery()
            .accountId(testEnv.operator.accountId)
            .execute(testEnv.client)

        XCTAssertEqual(operatorBalance.tokenBalances[token.id]!, testFungibleInitialBalance - UInt64(testAmount))
        XCTAssertEqual(operatorBalance.tokenBalances[nft.id]!, UInt64(testMintedNfts) - 2)
    }

    internal func testAirdropNonAssociatedTokens() async throws {
        let testEnv = try TestEnvironment.nonFree

        // create receiver with 0 auto associations and receiverSig = false
        let receiverKey = PrivateKey.generateEd25519()
        let receiverAccount = try await Account.create(testEnv, Key.single(receiverKey.publicKey), 0)

        // Create a token and an NFT
        let token = try await FungibleToken.create(testEnv, decimals: 3)
        let nft = try await Nft.create(testEnv)

        // Mint NFTs
        let mintReceipt = try await TokenMintTransaction()
            .tokenId(nft.id)
            .metadata(testMetadata)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let nftSerials = try XCTUnwrap(mintReceipt.serials)

        // Airdrop tokens
        var tx = try await TokenAirdropTransaction()
            .nftTransfer(nft.id.nft(nftSerials[0]), testEnv.operator.accountId, receiverAccount.id)
            .nftTransfer(nft.id.nft(nftSerials[1]), testEnv.operator.accountId, receiverAccount.id)
            .tokenTransfer(token.id, receiverAccount.id, testAmount)
            .tokenTransfer(token.id, testEnv.operator.accountId, -testAmount)
            .execute(testEnv.client)

        _ = try await tx.validateStatus(true).getReceipt(testEnv.client)
        let record = try await tx.getRecord(testEnv.client)

        // verify in the transaction record the pending airdrops
        XCTAssertNotNil(record.pendingAirdropRecords)
        XCTAssertFalse(record.pendingAirdropRecords.isEmpty)

        // Verify the receiver holds the tokens via query
        let receiverAccountBalance = try await AccountBalanceQuery()
            .accountId(receiverAccount.id)
            .execute(testEnv.client)

        XCTAssertNil(receiverAccountBalance.tokenBalances[token.id])
        XCTAssertNil(receiverAccountBalance.tokenBalances[nft.id])

        // Verify the operator does not hold the tokens
        let operatorBalance = try await AccountBalanceQuery()
            .accountId(testEnv.operator.accountId)
            .execute(testEnv.client)

        XCTAssertEqual(operatorBalance.tokenBalances[token.id], testFungibleInitialBalance)
        XCTAssertEqual(operatorBalance.tokenBalances[nft.id]!, UInt64(testMintedNfts))
    }

    internal func testAirdropToAlias() async throws {
        let testEnv = try TestEnvironment.nonFree

        // Create a token and an NFT
        let token = try await FungibleToken.create(testEnv, decimals: 3)
        let nft = try await Nft.create(testEnv)

        // Mint NFTs
        let mintReceipt = try await TokenMintTransaction()
            .tokenId(nft.id)
            .metadata(testMetadata)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let nftSerials = try XCTUnwrap(mintReceipt.serials)

        // Create an alias
        let aliasKey = PrivateKey.generateEd25519()
        let aliasAccountId = aliasKey.publicKey.toAccountId(shard: 0, realm: 0)

        // Airdrop tokens
        _ = try await TokenAirdropTransaction()
            .nftTransfer(nft.id.nft(nftSerials[0]), testEnv.operator.accountId, aliasAccountId)
            .nftTransfer(nft.id.nft(nftSerials[1]), testEnv.operator.accountId, aliasAccountId)
            .tokenTransfer(token.id, aliasAccountId, testAmount)
            .tokenTransfer(token.id, testEnv.operator.accountId, -testAmount)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Verify the receiver holds the tokens via query
        let receiverAccountBalance = try await AccountBalanceQuery()
            .accountId(aliasAccountId)
            .execute(testEnv.client)

        XCTAssertEqual(receiverAccountBalance.tokenBalances[token.id]!, UInt64(testAmount))
        XCTAssertEqual(receiverAccountBalance.tokenBalances[nft.id], 2)

        // Verify the operator does not hold the tokens
        let operatorBalance = try await AccountBalanceQuery()
            .accountId(testEnv.operator.accountId)
            .execute(testEnv.client)

        XCTAssertEqual(operatorBalance.tokenBalances[token.id]!, testFungibleInitialBalance - UInt64(testAmount))
        XCTAssertEqual(operatorBalance.tokenBalances[nft.id]!, UInt64(testMintedNfts) - 2)
    }

    internal func testAirdropWithCustomFees() async throws {
        let testEnv = try TestEnvironment.nonFree

        // create receiver with unlimited auto associations and receiverSig = false
        let receiverKey = PrivateKey.generateEd25519()
        let receiverAccount = try await Account.create(testEnv, Key.single(receiverKey.publicKey), -1)

        // Create a token
        let customFeeToken = try await FungibleToken.create(testEnv, decimals: 3)

        // Make the custom fee to be paid by the sender and the fee collector to be the operator account
        let fee = AnyCustomFee.fixed(
            FixedFee.init(
                amount: 1, denominatingTokenId: customFeeToken.id, feeCollectorAccountId: testEnv.operator.accountId,
                allCollectorsAreExempt: true))

        let createTokenReceipt = try await TokenCreateTransaction()
            .name("Test Token")
            .symbol("TST")
            .tokenMemo("Test Token Memo")
            .decimals(3)
            .initialSupply(testFungibleInitialBalance)
            .maxSupply(testFungibleInitialBalance)
            .treasuryAccountId(testEnv.operator.accountId)
            .tokenSupplyType(TokenSupplyType.finite)
            .supplyKey(Key.single(testEnv.operator.privateKey.publicKey))
            .adminKey(Key.single(testEnv.operator.privateKey.publicKey))
            .freezeKey(Key.single(testEnv.operator.privateKey.publicKey))
            .customFees([fee])
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let tokenId = try XCTUnwrap(createTokenReceipt.tokenId)

        // create receiver with unlimited auto associations and receiverSig = false
        let senderKey = PrivateKey.generateEd25519()
        let senderAccount = try await Account.create(testEnv, Key.single(senderKey.publicKey), -1)

        // associate the token to the sender
        _ = try await TokenAssociateTransaction()
            .accountId(senderAccount.id)
            .tokenIds([customFeeToken.id])
            .freezeWith(testEnv.client)
            .sign(senderKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // send tokens to the sender
        _ = try await TransferTransaction()
            .tokenTransfer(customFeeToken.id, testEnv.operator.accountId, -testAmount)
            .tokenTransfer(customFeeToken.id, senderAccount.id, testAmount)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await TransferTransaction()
            .tokenTransfer(tokenId, testEnv.operator.accountId, -testAmount)
            .tokenTransfer(tokenId, senderAccount.id, testAmount)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Airdrop the tokens from the sender to the receiver
        _ = try await TokenAirdropTransaction()
            .tokenTransfer(tokenId, receiverAccount.id, testAmount)
            .tokenTransfer(tokenId, senderAccount.id, -testAmount)
            .freezeWith(testEnv.client)
            .sign(senderKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Verify the receiver holds the tokens via query
        let receiverAccountBalance = try await AccountBalanceQuery()
            .accountId(receiverAccount.id)
            .execute(testEnv.client)

        XCTAssertEqual(receiverAccountBalance.tokenBalances[tokenId]!, UInt64(testAmount))

        let senderAccountBalance = try await AccountBalanceQuery()
            .accountId(senderAccount.id)
            .execute(testEnv.client)

        XCTAssertEqual(senderAccountBalance.tokenBalances[tokenId]!, 0)
        XCTAssertEqual(senderAccountBalance.tokenBalances[customFeeToken.id]!, UInt64(testAmount) - 1)

        // Verify the operator does not hold the tokens
        let operatorBalance = try await AccountBalanceQuery()
            .accountId(testEnv.operator.accountId)
            .execute(testEnv.client)

        XCTAssertEqual(
            operatorBalance.tokenBalances[customFeeToken.id]!, testFungibleInitialBalance - UInt64(testAmount) + 1)
        XCTAssertEqual(operatorBalance.tokenBalances[tokenId]!, testFungibleInitialBalance - UInt64(testAmount))
    }

    internal func testAirdropTokensWithReceiverSigRequiredFungible() async throws {
        let testEnv = try TestEnvironment.nonFree

        // Create a token
        let token = try await FungibleToken.create(testEnv, decimals: 3)

        // Create a receiver account with unlimited auto associations and receiverSig = true
        let receiverKey = PrivateKey.generateEd25519()
        let receiverAccountId = try await AccountCreateTransaction()
            .keyWithoutAlias(Key.single(receiverKey.publicKey))
            .initialBalance(Hbar(1))
            .receiverSignatureRequired(true)
            .maxAutomaticTokenAssociations(-1)
            .freezeWith(testEnv.client)
            .sign(receiverKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
            .accountId!

        // Airdrop tokens
        _ = try await TokenAirdropTransaction()
            .tokenTransfer(token.id, receiverAccountId, testAmount)
            .tokenTransfer(token.id, testEnv.operator.accountId, -testAmount)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    internal func testAirdropTokensWithReceiverSigRequiredNft() async throws {
        let testEnv = try TestEnvironment.nonFree

        // Create a nft
        let nft = try await Nft.create(testEnv)

        // Mint NFTs
        let mintReceipt = try await TokenMintTransaction()
            .tokenId(nft.id)
            .metadata(testMetadata)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let nftSerials = try XCTUnwrap(mintReceipt.serials)

        // Create a receiver account with unlimited auto associations and receiverSig = true
        let receiverKey = PrivateKey.generateEd25519()
        let receiverAccountId = try await AccountCreateTransaction()
            .keyWithoutAlias(Key.single(receiverKey.publicKey))
            .initialBalance(Hbar(1))
            .receiverSignatureRequired(true)
            .maxAutomaticTokenAssociations(-1)
            .freezeWith(testEnv.client)
            .sign(receiverKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
            .accountId!

        // Airdrop tokens
        _ = try await TokenAirdropTransaction()
            .nftTransfer(nft.id.nft(nftSerials[0]), testEnv.operator.accountId, receiverAccountId)
            .nftTransfer(nft.id.nft(nftSerials[1]), testEnv.operator.accountId, receiverAccountId)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    internal func testAirdropAllowanceAndWithoutBalanceFungibleFail() async throws {
        let testEnv = try TestEnvironment.nonFree

        // Create a fungible token
        let token = try await FungibleToken.create(testEnv, decimals: 3)

        // Create spender and approve its tokens
        let spenderKey = PrivateKey.generateEd25519()
        let spenderAccount = try await Account.create(testEnv, .single(spenderKey.publicKey), -1)

        // Create sender
        let senderKey = PrivateKey.generateEd25519()
        let senderAccount = try await Account.create(testEnv, .single(senderKey.publicKey), -1)

        // Transfer fungible tokens to sender
        _ = try await TransferTransaction()
            .tokenTransfer(token.id, testEnv.operator.accountId, -testAmount)
            .tokenTransfer(token.id, senderAccount.id, testAmount)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await AccountAllowanceApproveTransaction()
            .approveTokenAllowance(token.id, senderAccount.id, spenderAccount.id, UInt64(testAmount))
            .freezeWith(testEnv.client)
            .sign(senderKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Airdrop the tokens from the sender to the spender via approval
        // Fails with not supported status
        await assertThrowsHErrorAsync(
            try await TokenAirdropTransaction()
                .tokenTransfer(token.id, spenderAccount.id, testAmount)
                .approvedTokenTransfer(token.id, spenderAccount.id, -testAmount)
                .transactionId(TransactionId.generateFrom(spenderAccount.id))
                .freezeWith(testEnv.client)
                .sign(spenderKey)
                .execute(testEnv.client),
            "expected error Airdropping token"
        ) { error in
            guard case .transactionPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.transactionPreCheckStatus`")
                return
            }
            XCTAssertEqual(status, .notSupported)
        }
    }

    internal func testAirdropAllowanceAndWithoutBalanceNftFail() async throws {
        let testEnv = try TestEnvironment.nonFree

        // Create spender and approve its tokens
        let spenderKey = PrivateKey.generateEd25519()
        let spenderAccount = try await Account.create(testEnv, .single(spenderKey.publicKey), -1)

        // Create sender
        let senderKey = PrivateKey.generateEd25519()
        let senderAccount = try await Account.create(testEnv, .single(senderKey.publicKey), -1)

        // Create an nft
        let nft = try await Nft.create(testEnv)

        // Mint NFTs
        let mintReceipt = try await TokenMintTransaction()
            .tokenId(nft.id)
            .metadata(testMetadata)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let nftSerials = try XCTUnwrap(mintReceipt.serials)

        // Transfer fungible tokens to sender
        _ = try await TransferTransaction()
            .nftTransfer(nft.id.nft(nftSerials[0]), testEnv.operator.accountId, senderAccount.id)
            .nftTransfer(nft.id.nft(nftSerials[1]), testEnv.operator.accountId, senderAccount.id)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await AccountAllowanceApproveTransaction()
            .approveTokenNftAllowance(nft.id.nft(nftSerials[0]), senderAccount.id, spenderAccount.id)
            .approveTokenNftAllowance(nft.id.nft(nftSerials[1]), senderAccount.id, spenderAccount.id)
            .freezeWith(testEnv.client)
            .sign(senderKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Airdrop the tokens from the sender to the spender via approval
        // Fails with not supported status
        await assertThrowsHErrorAsync(
            try await TokenAirdropTransaction()
                .approvedNftTransfer(nft.id.nft(nftSerials[0]), spenderAccount.id, spenderAccount.id)
                .approvedNftTransfer(nft.id.nft(nftSerials[1]), spenderAccount.id, spenderAccount.id)
                .transactionId(TransactionId.generateFrom(spenderAccount.id))
                .freezeWith(testEnv.client)
                .sign(spenderKey)
                .execute(testEnv.client),
            "expected error Airdropping token"
        ) { error in
            guard case .transactionPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.transactionPreCheckStatus`")
                return
            }
            XCTAssertEqual(status, .notSupported)
        }
    }

    internal func testAirdropTokensWithInvalidBodyFail() async throws {
        let testEnv = try TestEnvironment.nonFree

        // Airdrop with no tokenID or NftID
        // fails with EMPTY_TOKEN_TRANSFER_BODY
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
        let token = try await FungibleToken.create(testEnv, decimals: 3)

        // Airdrop with invalid transfers
        // fails with INVALID_TRANSACTION_BODY
        await assertThrowsHErrorAsync(
            try await TokenAirdropTransaction()
                .tokenTransfer(token.id, testEnv.operator.accountId, testAmount)
                .tokenTransfer(token.id, testEnv.operator.accountId, testAmount)
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
