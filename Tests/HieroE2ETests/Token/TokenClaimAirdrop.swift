// SPDX-License-Identifier: Apache-2.0

import Hiero
import XCTest

internal class TokenClaimAirdrop: XCTestCase {
    internal func testClaimTokens() async throws {
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
        let record = try await TokenAirdropTransaction()
            .nftTransfer(nft.id.nft(nftSerials[0]), testEnv.operator.accountId, receiverAccount.id)
            .nftTransfer(nft.id.nft(nftSerials[1]), testEnv.operator.accountId, receiverAccount.id)
            .tokenTransfer(token.id, receiverAccount.id, testAmount)
            .tokenTransfer(token.id, testEnv.operator.accountId, -testAmount)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        // Verify the txn records
        XCTAssertEqual(record.pendingAirdropRecords.count, 3)

        XCTAssertEqual(record.pendingAirdropRecords[0].amount, 100)
        XCTAssertEqual(record.pendingAirdropRecords[0].pendingAirdropId.tokenId, token.id)
        XCTAssertNil(record.pendingAirdropRecords[0].pendingAirdropId.nftId)

        XCTAssertEqual(record.pendingAirdropRecords[1].amount, 0)
        XCTAssertEqual(record.pendingAirdropRecords[1].pendingAirdropId.nftId, nft.id.nft(nftSerials[0]))
        XCTAssertNil(record.pendingAirdropRecords[1].pendingAirdropId.tokenId)

        XCTAssertEqual(record.pendingAirdropRecords[2].amount, 0)
        XCTAssertEqual(record.pendingAirdropRecords[2].pendingAirdropId.nftId, nft.id.nft(nftSerials[1]))
        XCTAssertNil(record.pendingAirdropRecords[2].pendingAirdropId.tokenId)

        // Claim the tokens with the receiver account
        let tokenClaimRecord = try await TokenClaimAirdropTransaction()
            .addPendingAirdropId(record.pendingAirdropRecords[0].pendingAirdropId)
            .addPendingAirdropId(record.pendingAirdropRecords[1].pendingAirdropId)
            .addPendingAirdropId(record.pendingAirdropRecords[2].pendingAirdropId)
            .freezeWith(testEnv.client)
            .sign(receiverKey)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        // Verify in the transaction record the pending airdrop ids for nft and ft - should no longer exist
        XCTAssertEqual(tokenClaimRecord.pendingAirdropRecords.count, 0)

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

    internal func testClaimTokensToMultipleReceivers() async throws {
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

        let tokenClaimRecord = try await TokenClaimAirdropTransaction()
            .pendingAirdropIds(pendingAirdropIds)
            .freezeWith(testEnv.client)
            .sign(receiverKey1)
            .sign(receiverKey2)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        // Verify in the transaction record the pending airdrop ids for nft and ft - should no longer exist
        XCTAssertEqual(tokenClaimRecord.pendingAirdropRecords.count, 0)

        // Verify the receiver holds the tokens via query
        let receiverAccount1Balance = try await AccountBalanceQuery()
            .accountId(receiverAccount1.id)
            .execute(testEnv.client)

        XCTAssertEqual(receiverAccount1Balance.tokenBalances[token.id]!, UInt64(testAmount))
        XCTAssertEqual(receiverAccount1Balance.tokenBalances[nft.id], 2)

        // Verify the receiver holds the tokens via query
        let receiverAccount2Balance = try await AccountBalanceQuery()
            .accountId(receiverAccount2.id)
            .execute(testEnv.client)

        XCTAssertEqual(receiverAccount2Balance.tokenBalances[token.id]!, UInt64(testAmount))
        XCTAssertEqual(receiverAccount2Balance.tokenBalances[nft.id], 2)

        // Verify the operator does not hold the tokens
        let operatorBalance = try await AccountBalanceQuery()
            .accountId(testEnv.operator.accountId)
            .execute(testEnv.client)

        XCTAssertEqual(operatorBalance.tokenBalances[token.id], testFungibleInitialBalance - UInt64(testAmount) * 2)
        XCTAssertEqual(operatorBalance.tokenBalances[nft.id], UInt64(testMintedNfts) - 4)
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

        let tokenClaimRecord = try await TokenClaimAirdropTransaction()
            .pendingAirdropIds(pendingAirdropIds)
            .freezeWith(testEnv.client)
            .sign(receiverKey)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        // Verify in the transaction record the pending airdrop ids for nft and ft - should no longer exist
        XCTAssertEqual(tokenClaimRecord.pendingAirdropRecords.count, 0)

        // Verify the receiver holds the tokens via query
        let receiverAccount1Balance = try await AccountBalanceQuery()
            .accountId(receiverAccount.id)
            .execute(testEnv.client)

        XCTAssertEqual(receiverAccount1Balance.tokenBalances[token.id]!, UInt64(testAmount))
        XCTAssertEqual(receiverAccount1Balance.tokenBalances[nft.id], 2)

        // Verify the operator does not hold the tokens
        let operatorBalance = try await AccountBalanceQuery()
            .accountId(testEnv.operator.accountId)
            .execute(testEnv.client)

        XCTAssertEqual(operatorBalance.tokenBalances[token.id], testFungibleInitialBalance - UInt64(testAmount))
        XCTAssertEqual(operatorBalance.tokenBalances[nft.id], UInt64(testMintedNfts) - 2)
    }

    internal func testClaimTokensForNonExistingAirdropFail() async throws {
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

        // claim the tokens with the operator which does not have pending airdrops
        // fails with INVALID_SIGNATURE
        await assertThrowsHErrorAsync(
            try await TokenClaimAirdropTransaction()
                .addPendingAirdropId(record.pendingAirdropRecords[0].pendingAirdropId)
                .execute(testEnv.client)
                .getRecord(testEnv.client),
            "expected error Claiming token"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }
            XCTAssertEqual(status, .invalidSignature)
        }
    }

    internal func testClaimAlreadyClaimedAirdropFail() async throws {
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

        // Claim the tokens with the receiver
        _ = try await TokenClaimAirdropTransaction()
            .addPendingAirdropId(record.pendingAirdropRecords[0].pendingAirdropId)
            .freezeWith(testEnv.client)
            .sign(receiverKey)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        // claim the tokens with the operator which does not have pending airdrops
        // fails with INVALID_SIGNATURE
        await assertThrowsHErrorAsync(
            try await TokenClaimAirdropTransaction()
                .addPendingAirdropId(record.pendingAirdropRecords[0].pendingAirdropId)
                .freezeWith(testEnv.client)
                .sign(receiverKey)
                .execute(testEnv.client)
                .getRecord(testEnv.client),
            "expected error Claiming token"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }
            XCTAssertEqual(status, .invalidPendingAirdropId)
        }
    }

    internal func disabled_testClaimEmptyPendingAirdropFail() async throws {
        let testEnv = try TestEnvironment.nonFree

        // Claim the tokens with the receiver without setting pendingAirdropIds
        // fails with EMPTY_PENDING_AIRDROP_ID_LIST
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

    internal func disabled_testClaimDuplicateEntriesFail() async throws {
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

        // Claim the tokens with duplicate pending airdrop token ids
        // fails with PENDING_AIRDROP_ID_REPEATED
        await assertThrowsHErrorAsync(
            try await TokenClaimAirdropTransaction()
                .addPendingAirdropId(record.pendingAirdropRecords[0].pendingAirdropId)
                .addPendingAirdropId(record.pendingAirdropRecords[0].pendingAirdropId)
                .execute(testEnv.client)
                .getRecord(testEnv.client),
            "expected error Claiming token"
        ) { error in
            guard case .transactionPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.transactionPreCheckStatus`")
                return
            }
            XCTAssertEqual(status, .pendingAirdropIdRepeated)
        }
    }

    internal func testClaimDeletedTokensFail() async throws {
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

        // Claim the tokens with receiver
        // fails with TOKEN_IS_DELETED
        await assertThrowsHErrorAsync(
            try await TokenClaimAirdropTransaction()
                .addPendingAirdropId(record.pendingAirdropRecords[0].pendingAirdropId)
                .freezeWith(testEnv.client)
                .sign(receiverKey)
                .execute(testEnv.client)
                .getRecord(testEnv.client),
            "expected error Claiming token"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }
            XCTAssertEqual(status, .tokenWasDeleted)
        }
    }
}
