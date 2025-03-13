// SPDX-License-Identifier: Apache-2.0

import Hiero
import XCTest

internal class TokenCancelAirdrop: XCTestCase {
    internal func testCancelTokens() async throws {
        let testEnv = try TestEnvironment.nonFree

        // Create a receiver account with unlimited auto associations
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
        var record = try await TokenAirdropTransaction()
            .nftTransfer(nft.id.nft(nftSerials[0]), testEnv.operator.accountId, receiverAccount.id)
            .nftTransfer(nft.id.nft(nftSerials[1]), testEnv.operator.accountId, receiverAccount.id)
            .tokenTransfer(token.id, receiverAccount.id, testAmount)
            .tokenTransfer(token.id, testEnv.operator.accountId, -testAmount)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        // Sender cancels the airdrop
        record = try await TokenCancelAirdropTransaction()
            .addPendingAirdropId(record.pendingAirdropRecords[0].pendingAirdropId)
            .addPendingAirdropId(record.pendingAirdropRecords[1].pendingAirdropId)
            .addPendingAirdropId(record.pendingAirdropRecords[2].pendingAirdropId)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        // Verify in the transaction record the pending airdrop ids for nft and ft - should no longer exist
        XCTAssertEqual(record.pendingAirdropRecords.count, 0)

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
        XCTAssertEqual(operatorBalance.tokenBalances[nft.id], UInt64(testMintedNfts))
    }

    internal func testCancelTokensWhenFrozen() async throws {
        let testEnv = try TestEnvironment.nonFree

        // create receiver with 0 auto associations
        let receiverKey = PrivateKey.generateEd25519()
        let receiverAccount = try await Account.create(testEnv, Key.single(receiverKey.publicKey), 0)

        // Create a token
        let token = try await FungibleToken.create(testEnv, decimals: 3)

        // Airdrop tokens
        let record = try await TokenAirdropTransaction()
            .tokenTransfer(token.id, receiverAccount.id, testAmount)
            .tokenTransfer(token.id, testEnv.operator.accountId, -testAmount)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        // Associate the receiver account with the token
        _ = try await TokenAssociateTransaction()
            .accountId(receiverAccount.id)
            .tokenIds([token.id])
            .freezeWith(testEnv.client)
            .sign(receiverKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Freeze the token
        _ = try await TokenFreezeTransaction()
            .tokenId(token.id)
            .accountId(receiverAccount.id)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Cancel the airdrop
        _ = try await TokenCancelAirdropTransaction()
            .addPendingAirdropId(record.pendingAirdropRecords[0].pendingAirdropId)
            .execute(testEnv.client)
            .getRecord(testEnv.client)
    }

    internal func testCancelTokensWhenPaused() async throws {
        let testEnv = try TestEnvironment.nonFree

        // Create a token
        let token = try await FungibleToken.create(testEnv, decimals: 3)

        // create receiver with 0 auto associations
        let receiverKey = PrivateKey.generateEd25519()
        let receiverAccount = try await Account.create(testEnv, Key.single(receiverKey.publicKey), 0)

        // Airdrop some of the tokens to the receiver
        let record = try await TokenAirdropTransaction()
            .tokenTransfer(token.id, receiverAccount.id, testAmount)
            .tokenTransfer(token.id, testEnv.operator.accountId, -testAmount)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        // Pause the token
        _ = try await TokenPauseTransaction()
            .tokenId(token.id)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Cancel the airdrop
        _ = try await TokenCancelAirdropTransaction()
            .addPendingAirdropId(record.pendingAirdropRecords[0].pendingAirdropId)
            .execute(testEnv.client)
            .getRecord(testEnv.client)
    }

    internal func testCancelTokensWhenTokenIsDeleted() async throws {
        let testEnv = try TestEnvironment.nonFree

        // Create a token
        let token = try await FungibleToken.create(testEnv, decimals: 3)

        // create receiver with 0 auto associations
        let receiverKey = PrivateKey.generateEd25519()
        let receiverAccount = try await Account.create(testEnv, Key.single(receiverKey.publicKey), 0)

        // airdrop the tokens from sender to receiver
        let record = try await TokenAirdropTransaction()
            .tokenTransfer(token.id, receiverAccount.id, testAmount)
            .tokenTransfer(token.id, testEnv.operator.accountId, -testAmount)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        // Delete the token
        _ = try await TokenDeleteTransaction()
            .tokenId(token.id)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Cancel the airdrop
        _ = try await TokenCancelAirdropTransaction()
            .addPendingAirdropId(record.pendingAirdropRecords[0].pendingAirdropId)
            .execute(testEnv.client)
            .getRecord(testEnv.client)
    }

    internal func testCancelTokensToMultipleReceivers() async throws {
        let testEnv = try TestEnvironment.nonFree

        // create receiver1 with 0 auto associations
        let receiverKey1 = PrivateKey.generateEd25519()
        let receiverAccount1 = try await Account.create(testEnv, Key.single(receiverKey1.publicKey), 0)

        // create receiver2 with 0 auto associations
        let receiverKey2 = PrivateKey.generateEd25519()
        let receiverAccount2 = try await Account.create(testEnv, Key.single(receiverKey2.publicKey), 0)

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
        let record = try await TokenAirdropTransaction()
            .nftTransfer(nft.id.nft(nftSerials[0]), testEnv.operator.accountId, receiverAccount1.id)
            .nftTransfer(nft.id.nft(nftSerials[1]), testEnv.operator.accountId, receiverAccount1.id)
            .tokenTransfer(token.id, receiverAccount1.id, testAmount)
            .tokenTransfer(token.id, testEnv.operator.accountId, -testAmount)
            .nftTransfer(nft.id.nft(nftSerials[2]), testEnv.operator.accountId, receiverAccount2.id)
            .nftTransfer(nft.id.nft(nftSerials[3]), testEnv.operator.accountId, receiverAccount2.id)
            .tokenTransfer(token.id, receiverAccount2.id, testAmount)
            .tokenTransfer(token.id, testEnv.operator.accountId, -testAmount)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        // Verify the txn records
        XCTAssertEqual(record.pendingAirdropRecords.count, 6)

        // claim the tokens signing with receiver1 and receiver2
        let pendingAirdropIds = record.pendingAirdropRecords.map { $0.pendingAirdropId }

        let tokenClaimRecord = try await TokenCancelAirdropTransaction()
            .pendingAirdropIds(pendingAirdropIds)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        // Verify in the transaction record the pending airdrop ids for nft and ft - should no longer exist
        XCTAssertEqual(tokenClaimRecord.pendingAirdropRecords.count, 0)

        // Verify the receiver1 does not hold the tokens via query
        let receiverAccount1Balance = try await AccountBalanceQuery()
            .accountId(receiverAccount1.id)
            .execute(testEnv.client)

        XCTAssertNil(receiverAccount1Balance.tokenBalances[token.id])
        XCTAssertNil(receiverAccount1Balance.tokenBalances[nft.id])

        // Verify the receiver2 does not hold the tokens via query
        let receiverAccount2Balance = try await AccountBalanceQuery()
            .accountId(receiverAccount2.id)
            .execute(testEnv.client)

        XCTAssertNil(receiverAccount2Balance.tokenBalances[token.id])
        XCTAssertNil(receiverAccount2Balance.tokenBalances[nft.id])

        // Verify the operator does hold the tokens
        let operatorBalance = try await AccountBalanceQuery()
            .accountId(testEnv.operator.accountId)
            .execute(testEnv.client)

        XCTAssertEqual(operatorBalance.tokenBalances[token.id], testFungibleInitialBalance)
        XCTAssertEqual(operatorBalance.tokenBalances[nft.id], UInt64(testMintedNfts))
    }

    internal func testClaimTokensToMultipleAirdropTxns() async throws {
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

        // create receiver with 0 auto associations
        let receiverKey = PrivateKey.generateEd25519()
        let receiverAccount = try await Account.create(testEnv, Key.single(receiverKey.publicKey), 0)

        // airdrop some of the tokens to the receiver
        let record1 = try await TokenAirdropTransaction()
            .nftTransfer(nft.id.nft(nftSerials[0]), testEnv.operator.accountId, receiverAccount.id)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        // Airdrop some of the tokens to the receiver
        let record2 = try await TokenAirdropTransaction()
            .nftTransfer(nft.id.nft(nftSerials[1]), testEnv.operator.accountId, receiverAccount.id)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        // Airdrop some of the tokens to the receiver
        let record3 = try await TokenAirdropTransaction()
            .tokenTransfer(token.id, receiverAccount.id, testAmount)
            .tokenTransfer(token.id, testEnv.operator.accountId, -testAmount)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        // Get the PendingIds from the records
        let pendingAirdropIds: [PendingAirdropId] = [
            record1.pendingAirdropRecords[0].pendingAirdropId, record2.pendingAirdropRecords[0].pendingAirdropId,
            record3.pendingAirdropRecords[0].pendingAirdropId,
        ]

        let tokenCancelRecord = try await TokenCancelAirdropTransaction()
            .pendingAirdropIds(pendingAirdropIds)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        // Verify in the transaction record the pending airdrop ids for nft and ft - should no longer exist
        XCTAssertEqual(tokenCancelRecord.pendingAirdropRecords.count, 0)

        // Verify the receiver holds the tokens via query
        let receiverAccount1Balance = try await AccountBalanceQuery()
            .accountId(receiverAccount.id)
            .execute(testEnv.client)

        XCTAssertNil(receiverAccount1Balance.tokenBalances[token.id])
        XCTAssertNil(receiverAccount1Balance.tokenBalances[nft.id])

        // Verify the operator does not hold the tokens
        let operatorBalance = try await AccountBalanceQuery()
            .accountId(testEnv.operator.accountId)
            .execute(testEnv.client)

        XCTAssertEqual(operatorBalance.tokenBalances[token.id], testFungibleInitialBalance)
        XCTAssertEqual(operatorBalance.tokenBalances[nft.id], UInt64(testMintedNfts))
    }

    internal func testCancelTokensForNonExistingAirdropFail() async throws {
        let testEnv = try TestEnvironment.nonFree

        // Create a token
        let token = try await FungibleToken.create(testEnv, decimals: 3)

        // create receiver with 0 auto associations
        let receiverKey = PrivateKey.generateEd25519()
        let receiverAccount = try await Account.create(testEnv, Key.single(receiverKey.publicKey), 0)

        // airdrop the tokens
        let record = try await TokenAirdropTransaction()
            .tokenTransfer(token.id, receiverAccount.id, testAmount)
            .tokenTransfer(token.id, testEnv.operator.accountId, -testAmount)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        // Create receiver with 0 auto associations
        let randomKey = PrivateKey.generateEd25519()
        let randomAccount = try await Account.create(testEnv, Key.single(randomKey.publicKey), 0)

        // cancel the tokens with the random account which has not created pending airdrops
        // fails with INVALID_SIGNATURE
        await assertThrowsHErrorAsync(
            try await TokenCancelAirdropTransaction()
                .transactionId(TransactionId.generateFrom(randomAccount.id))
                .addPendingAirdropId(record.pendingAirdropRecords[0].pendingAirdropId)
                .execute(testEnv.client)
                .getRecord(testEnv.client),
            "expected error Cancel airdrop"
        ) { error in
            guard case .transactionPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.transactionPreCheckStatus`")
                return
            }
            XCTAssertEqual(status, .invalidSignature)
        }
    }

    internal func testCancelCancelledAirdropFail() async throws {
        let testEnv = try TestEnvironment.nonFree

        // Create a token and an NFT
        let token = try await FungibleToken.create(testEnv, decimals: 3)

        // create receiver with 0 auto associations
        let receiverKey = PrivateKey.generateEd25519()
        let receiverAccount = try await Account.create(testEnv, Key.single(receiverKey.publicKey), 0)

        // airdrop the tokens
        let record = try await TokenAirdropTransaction()
            .tokenTransfer(token.id, receiverAccount.id, testAmount)
            .tokenTransfer(token.id, testEnv.operator.accountId, -testAmount)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        // Cancel the tokens with the receiver
        _ = try await TokenCancelAirdropTransaction()
            .addPendingAirdropId(record.pendingAirdropRecords[0].pendingAirdropId)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        // Cancel the tokens with the receiver again
        // fails with INVALID_PENDING_AIRDROP_ID
        await assertThrowsHErrorAsync(
            try await TokenCancelAirdropTransaction()
                .addPendingAirdropId(record.pendingAirdropRecords[0].pendingAirdropId)
                .execute(testEnv.client)
                .getRecord(testEnv.client),
            "expected error Cancel token"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }
            XCTAssertEqual(status, .invalidPendingAirdropId)
        }
    }

    internal func testCancelEmptyPendingAirdropFail() async throws {
        let testEnv = try TestEnvironment.nonFree

        // Cancel the tokens with the receiver without setting pendingAirdropIds
        // fails with EMPTY_PENDING_AIRDROP_ID_LIST
        await assertThrowsHErrorAsync(
            try await TokenCancelAirdropTransaction()
                .execute(testEnv.client)
                .getRecord(testEnv.client),
            "expected error Cancel token"
        ) { error in
            guard case .responseStatusUnrecognized = error.kind else {
                XCTFail("`\(error.kind)` is not `.responseStatusUnrecognized`")
                return
            }
            XCTAssertEqual(error.kind, .responseStatusUnrecognized)
        }
    }

    internal func testCancelDuplicateEntriesFail() async throws {
        let testEnv = try TestEnvironment.nonFree

        // Create a token
        let token = try await FungibleToken.create(testEnv, decimals: 3)

        // create receiver with 0 auto associations
        let receiverKey = PrivateKey.generateEd25519()
        let receiverAccount = try await Account.create(testEnv, Key.single(receiverKey.publicKey), 0)

        // airdrop the tokens
        let record = try await TokenAirdropTransaction()
            .tokenTransfer(token.id, receiverAccount.id, testAmount)
            .tokenTransfer(token.id, testEnv.operator.accountId, -testAmount)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        // Cancel the tokens with the receiver again
        // fails with INVALID_PENDING_AIRDROP_ID
        await assertThrowsHErrorAsync(
            try await TokenCancelAirdropTransaction()
                .addPendingAirdropId(record.pendingAirdropRecords[0].pendingAirdropId)
                .addPendingAirdropId(record.pendingAirdropRecords[0].pendingAirdropId)
                .execute(testEnv.client)
                .getRecord(testEnv.client),
            "expected error Claiming token"
        ) { error in
            guard case .responseStatusUnrecognized = error.kind else {
                XCTFail("`\(error.kind)` is not `.responseStatusUnrecognized`")
                return
            }
            XCTAssertEqual(error.kind, .responseStatusUnrecognized)
        }
    }
}
