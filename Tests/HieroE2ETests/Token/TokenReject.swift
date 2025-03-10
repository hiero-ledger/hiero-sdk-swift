// SPDX-License-Identifier: Apache-2.0

import Hiero
import XCTest

internal class TokenReject: XCTestCase {
    internal func testBasicFtReject() async throws {
        let testEnv = try TestEnvironment.nonFree

        let ft1 = try await FungibleToken.create(testEnv, decimals: 3)
        let ft2 = try await FungibleToken.create(testEnv, decimals: 3)
        let receiverAccountKey = PrivateKey.generateEd25519()
        let receiverAccount = try await Account.create(testEnv, Key.single(receiverAccountKey.publicKey), 100)

        _ = try await TransferTransaction()
            .tokenTransfer(ft1.id, testEnv.operator.accountId, -10)
            .tokenTransfer(ft1.id, receiverAccount.id, 10)
            .tokenTransfer(ft2.id, testEnv.operator.accountId, -10)
            .tokenTransfer(ft2.id, receiverAccount.id, 10)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await TokenRejectTransaction()
            .owner(receiverAccount.id)
            .tokenIds([ft1.id, ft2.id])
            .freezeWith(testEnv.client)
            .sign(receiverAccountKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let receiverBalance = try await AccountBalanceQuery()
            .accountId(receiverAccount.id)
            .execute(testEnv.client)

        XCTAssertEqual(receiverBalance.tokenBalances[ft1.id], 0)
        XCTAssertEqual(receiverBalance.tokenBalances[ft2.id], 0)

        let treasuryAccountBalance = try await AccountBalanceQuery()
            .accountId(testEnv.operator.accountId)
            .execute(testEnv.client)

        XCTAssertEqual(treasuryAccountBalance.tokenBalances[ft1.id], 1_000_000)
        XCTAssertEqual(treasuryAccountBalance.tokenBalances[ft2.id], 1_000_000)

        addTeardownBlock {
            try await ft1.delete(testEnv)
            try await ft2.delete(testEnv)
        }
    }

    internal func testBasicNftReject() async throws {
        let testEnv = try TestEnvironment.nonFree

        let nft1 = try await Nft.create(testEnv)
        let nft2 = try await Nft.create(testEnv)
        let receiverAccountKey = PrivateKey.generateEd25519()
        let receiverAccount = try await Account.create(testEnv, Key.single(receiverAccountKey.publicKey), 100)

        _ = try await TokenMintTransaction()
            .tokenId(nft1.id)
            .metadata(Array(repeating: Data([9, 1, 6]), count: 5))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let nftMintReceipt2 = try await TokenMintTransaction()
            .tokenId(nft2.id)
            .metadata(Array(repeating: Data([3, 6, 9]), count: 5))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let nftSerials = try XCTUnwrap(nftMintReceipt2.serials)

        _ = try await TransferTransaction()
            .nftTransfer(nft1.id.nft(nftSerials[0]), testEnv.operator.accountId, receiverAccount.id)
            .nftTransfer(nft1.id.nft(nftSerials[1]), testEnv.operator.accountId, receiverAccount.id)
            .nftTransfer(nft2.id.nft(nftSerials[0]), testEnv.operator.accountId, receiverAccount.id)
            .nftTransfer(nft2.id.nft(nftSerials[1]), testEnv.operator.accountId, receiverAccount.id)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await TokenRejectTransaction()
            .owner(receiverAccount.id)
            .nftIds([nft1.id.nft(nftSerials[1]), nft2.id.nft(nftSerials[1])])
            .freezeWith(testEnv.client)
            .sign(receiverAccountKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let nft1Info = try await TokenNftInfoQuery()
            .nftId(nft1.id.nft(nftSerials[1]))
            .execute(testEnv.client)

        XCTAssertEqual(nft1Info.accountId, testEnv.operator.accountId)

        let nft2Info = try await TokenNftInfoQuery()
            .nftId(nft2.id.nft(nftSerials[1]))
            .execute(testEnv.client)

        XCTAssertEqual(nft2Info.accountId, testEnv.operator.accountId)

        addTeardownBlock {
            try await nft1.delete(testEnv)
            try await nft2.delete(testEnv)
        }
    }

    internal func testFtAndNftReject() async throws {
        let testEnv = try TestEnvironment.nonFree

        let ft1 = try await FungibleToken.create(testEnv, decimals: 3)
        let ft2 = try await FungibleToken.create(testEnv, decimals: 3)
        let nft1 = try await Nft.create(testEnv)
        let nft2 = try await Nft.create(testEnv)
        let receiverAccountKey = PrivateKey.generateEd25519()
        let receiverAccount = try await Account.create(testEnv, Key.single(receiverAccountKey.publicKey), 100)

        _ = try await TokenMintTransaction()
            .tokenId(nft1.id)
            .metadata(Array(repeating: Data([9, 1, 6]), count: 5))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let nftMintReceipt2 = try await TokenMintTransaction()
            .tokenId(nft2.id)
            .metadata(Array(repeating: Data([3, 6, 9]), count: 5))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let nftSerials = try XCTUnwrap(nftMintReceipt2.serials)

        _ = try await TransferTransaction()
            .tokenTransfer(ft1.id, testEnv.operator.accountId, -10)
            .tokenTransfer(ft1.id, receiverAccount.id, 10)
            .tokenTransfer(ft2.id, testEnv.operator.accountId, -10)
            .tokenTransfer(ft2.id, receiverAccount.id, 10)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await TransferTransaction()
            .nftTransfer(nft1.id.nft(nftSerials[0]), testEnv.operator.accountId, receiverAccount.id)
            .nftTransfer(nft1.id.nft(nftSerials[1]), testEnv.operator.accountId, receiverAccount.id)
            .nftTransfer(nft2.id.nft(nftSerials[0]), testEnv.operator.accountId, receiverAccount.id)
            .nftTransfer(nft2.id.nft(nftSerials[1]), testEnv.operator.accountId, receiverAccount.id)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await TokenRejectTransaction()
            .owner(receiverAccount.id)
            .tokenIds([ft1.id, ft2.id])
            .nftIds([nft1.id.nft(nftSerials[1]), nft2.id.nft(nftSerials[1])])
            .freezeWith(testEnv.client)
            .sign(receiverAccountKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let receiverAccountBalance = try await AccountBalanceQuery()
            .accountId(receiverAccount.id)
            .execute(testEnv.client)

        XCTAssertEqual(receiverAccountBalance.tokenBalances[ft1.id], 0)
        XCTAssertEqual(receiverAccountBalance.tokenBalances[ft2.id], 0)
        XCTAssertEqual(receiverAccountBalance.tokenBalances[nft1.id], 1)
        XCTAssertEqual(receiverAccountBalance.tokenBalances[nft2.id], 1)

        let treasuryAccountBalance = try await AccountBalanceQuery()
            .accountId(testEnv.operator.accountId)
            .execute(testEnv.client)

        XCTAssertEqual(treasuryAccountBalance.tokenBalances[ft1.id], 1_000_000)
        XCTAssertEqual(treasuryAccountBalance.tokenBalances[ft2.id], 1_000_000)

        let nft1Info = try await TokenNftInfoQuery()
            .nftId(nft1.id.nft(nftSerials[1]))
            .execute(testEnv.client)

        XCTAssertEqual(nft1Info.accountId, testEnv.operator.accountId)

        let nft2Info = try await TokenNftInfoQuery()
            .nftId(nft2.id.nft(nftSerials[1]))
            .execute(testEnv.client)

        XCTAssertEqual(nft2Info.accountId, testEnv.operator.accountId)

        addTeardownBlock {
            try await ft1.delete(testEnv)
            try await ft2.delete(testEnv)
            try await nft1.delete(testEnv)
            try await nft2.delete(testEnv)
        }
    }

    internal func testFtAndNftFreeze() async throws {
        let testEnv = try TestEnvironment.nonFree

        let ft1 = try await FungibleToken.create(testEnv, decimals: 3)
        let ft2 = try await FungibleToken.create(testEnv, decimals: 3)
        let nft1 = try await Nft.create(testEnv)
        let nft2 = try await Nft.create(testEnv)
        let receiverAccountKey = PrivateKey.generateEd25519()
        let receiverAccount = try await Account.create(testEnv, Key.single(receiverAccountKey.publicKey), 100)

        _ = try await TokenMintTransaction()
            .tokenId(nft1.id)
            .metadata(Array(repeating: Data([9, 1, 6]), count: 5))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let nftMintReceipt2 = try await TokenMintTransaction()
            .tokenId(nft2.id)
            .metadata(Array(repeating: Data([3, 6, 9]), count: 5))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let nftSerials = try XCTUnwrap(nftMintReceipt2.serials)

        _ = try await TransferTransaction()
            .tokenTransfer(ft1.id, testEnv.operator.accountId, -10)
            .tokenTransfer(ft1.id, receiverAccount.id, 10)
            .tokenTransfer(ft2.id, testEnv.operator.accountId, -10)
            .tokenTransfer(ft2.id, receiverAccount.id, 10)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await TransferTransaction()
            .nftTransfer(nft1.id.nft(nftSerials[0]), testEnv.operator.accountId, receiverAccount.id)
            .nftTransfer(nft1.id.nft(nftSerials[1]), testEnv.operator.accountId, receiverAccount.id)
            .nftTransfer(nft2.id.nft(nftSerials[0]), testEnv.operator.accountId, receiverAccount.id)
            .nftTransfer(nft2.id.nft(nftSerials[1]), testEnv.operator.accountId, receiverAccount.id)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await TokenRejectTransaction()
            .owner(receiverAccount.id)
            .tokenIds([ft1.id, ft2.id])
            .nftIds([nft1.id.nft(nftSerials[1]), nft2.id.nft(nftSerials[1])])
            .freezeWith(testEnv.client)
            .sign(receiverAccountKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let receiverAccountBalance = try await AccountBalanceQuery()
            .accountId(receiverAccount.id)
            .execute(testEnv.client)

        XCTAssertEqual(receiverAccountBalance.tokenBalances[ft1.id], 0)
        XCTAssertEqual(receiverAccountBalance.tokenBalances[ft2.id], 0)
        XCTAssertEqual(receiverAccountBalance.tokenBalances[nft1.id], 1)
        XCTAssertEqual(receiverAccountBalance.tokenBalances[nft2.id], 1)

        let treasuryAccountBalance = try await AccountBalanceQuery()
            .accountId(testEnv.operator.accountId)
            .execute(testEnv.client)

        XCTAssertEqual(treasuryAccountBalance.tokenBalances[ft1.id], 1_000_000)
        XCTAssertEqual(treasuryAccountBalance.tokenBalances[ft2.id], 1_000_000)

        let nft1Info = try await TokenNftInfoQuery()
            .nftId(nft1.id.nft(nftSerials[1]))
            .execute(testEnv.client)

        XCTAssertEqual(nft1Info.accountId, testEnv.operator.accountId)

        let nft2Info = try await TokenNftInfoQuery()
            .nftId(nft2.id.nft(nftSerials[1]))
            .execute(testEnv.client)

        XCTAssertEqual(nft2Info.accountId, testEnv.operator.accountId)

        addTeardownBlock {
            try await ft1.delete(testEnv)
            try await ft2.delete(testEnv)
            try await nft1.delete(testEnv)
            try await nft2.delete(testEnv)
        }
    }

    internal func testFtAndNftPaused() async throws {
        let testEnv = try TestEnvironment.nonFree

        let ft = try await FungibleToken.create(testEnv, decimals: 3)
        let nft = try await Nft.create(testEnv)
        let receiverAccountKey = PrivateKey.generateEd25519()
        let receiverAccount = try await Account.create(testEnv, Key.single(receiverAccountKey.publicKey), 100)

        _ = try await TransferTransaction()
            .tokenTransfer(ft.id, testEnv.operator.accountId, -10)
            .tokenTransfer(ft.id, receiverAccount.id, 10)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await TokenPauseTransaction()
            .tokenId(ft.id)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        await assertThrowsHErrorAsync(
            try await TokenRejectTransaction()
                .owner(receiverAccount.id)
                .addTokenId(ft.id)
                .freezeWith(testEnv.client)
                .sign(receiverAccountKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .tokenIsPaused)
        }

        let mintReceipt = try await TokenMintTransaction()
            .tokenId(nft.id)
            .metadata(Array(repeating: Data([9, 1, 6]), count: 5))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let nftSerials = try XCTUnwrap(mintReceipt.serials)

        _ = try await TransferTransaction()
            .nftTransfer(nft.id.nft(nftSerials[0]), testEnv.operator.accountId, receiverAccount.id)
            .nftTransfer(nft.id.nft(nftSerials[1]), testEnv.operator.accountId, receiverAccount.id)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await TokenPauseTransaction()
            .tokenId(nft.id)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        await assertThrowsHErrorAsync(
            try await TokenRejectTransaction()
                .owner(receiverAccount.id)
                .addNftId(nft.id.nft(nftSerials[1]))
                .freezeWith(testEnv.client)
                .sign(receiverAccountKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .tokenIsPaused)
        }
    }

    internal func testRemoveAllowance() async throws {
        if true {
            throw XCTSkip("Temporarily disabled til server side fix.")
        }

        let testEnv = try TestEnvironment.nonFree

        let ft = try await FungibleToken.create(testEnv, decimals: 3)
        let receiverAccountKey = PrivateKey.generateEd25519()
        let receiverAccount = try await Account.create(testEnv, Key.single(receiverAccountKey.publicKey), -1)

        let spenderAccountKey = PrivateKey.generateEd25519()
        let spenderCreateReceipt = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(spenderAccountKey.publicKey))
            .initialBalance(Hbar(1))
            .maxAutomaticTokenAssociations(-1)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let spenderAccountId = try XCTUnwrap(spenderCreateReceipt.accountId)

        _ = try await TransferTransaction()
            .tokenTransfer(ft.id, testEnv.operator.accountId, -10)
            .tokenTransfer(ft.id, receiverAccount.id, 10)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await AccountAllowanceApproveTransaction()
            .approveTokenAllowance(ft.id, receiverAccount.id, spenderAccountId, 10)
            .freezeWith(testEnv.client)
            .sign(receiverAccountKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await TransferTransaction()
            .approvedTokenTransfer(ft.id, receiverAccount.id, -5)
            .tokenTransfer(ft.id, spenderAccountId, 5)
            .transactionId(TransactionId.generateFrom(spenderAccountId))
            .freezeWith(testEnv.client)
            .sign(spenderAccountKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await TokenRejectTransaction()
            .owner(receiverAccount.id)
            .addTokenId(ft.id)
            .freezeWith(testEnv.client)
            .sign(receiverAccountKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        await assertThrowsHErrorAsync(
            try await TransferTransaction()
                .approvedTokenTransfer(ft.id, receiverAccount.id, -5)
                .tokenTransfer(ft.id, spenderAccountId, 5)
                .transactionId(TransactionId.generateFrom(spenderAccountId))
                .freezeWith(testEnv.client)
                .sign(spenderAccountKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .spenderDoesNotHaveAllowance)
        }

        let nft = try await Nft.create(testEnv)

        let mintReceipt = try await TokenMintTransaction()
            .tokenId(nft.id)
            .metadata(Array(repeating: Data([4, 2, 0]), count: 4))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let nftSerials = try XCTUnwrap(mintReceipt.serials)

        _ = try await TransferTransaction()
            .nftTransfer(nft.id.nft(nftSerials[0]), testEnv.operator.accountId, receiverAccount.id)
            .nftTransfer(nft.id.nft(nftSerials[1]), testEnv.operator.accountId, receiverAccount.id)
            .nftTransfer(nft.id.nft(nftSerials[2]), testEnv.operator.accountId, receiverAccount.id)
            .nftTransfer(nft.id.nft(nftSerials[3]), testEnv.operator.accountId, receiverAccount.id)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await AccountAllowanceApproveTransaction()
            .approveTokenNftAllowance(nft.id.nft(nftSerials[0]), receiverAccount.id, spenderAccountId)
            .approveTokenNftAllowance(nft.id.nft(nftSerials[1]), receiverAccount.id, spenderAccountId)
            .freezeWith(testEnv.client)
            .sign(receiverAccountKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await TransferTransaction()
            .approvedNftTransfer(nft.id.nft(nftSerials[0]), receiverAccount.id, spenderAccountId)
            .transactionId(TransactionId.generateFrom(spenderAccountId))
            .freezeWith(testEnv.client)
            .sign(spenderAccountKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await TokenRejectTransaction()
            .owner(receiverAccount.id)
            .nftIds([nft.id.nft(nftSerials[1]), nft.id.nft(nftSerials[2])])
            .freezeWith(testEnv.client)
            .sign(receiverAccountKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        await assertThrowsHErrorAsync(
            try await TransferTransaction()
                .approvedNftTransfer(nft.id.nft(nftSerials[1]), receiverAccount.id, spenderAccountId)
                .approvedNftTransfer(nft.id.nft(nftSerials[2]), receiverAccount.id, spenderAccountId)
                .transactionId(TransactionId.generateFrom(spenderAccountId))
                .freezeWith(testEnv.client)
                .sign(spenderAccountKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .spenderDoesNotHaveAllowance)
        }

        addTeardownBlock {
            try await ft.delete(testEnv)
            try await nft.delete(testEnv)
        }
    }

    internal func testAddOrSetNftTokenIdFail() async throws {
        let testEnv = try TestEnvironment.nonFree

        let nft = try await Nft.create(testEnv)
        let receiverAccountKey = PrivateKey.generateEd25519()
        let receiverAccount = try await Account.create(testEnv, Key.single(receiverAccountKey.publicKey), 100)

        let mintReceipt = try await TokenMintTransaction()
            .tokenId(nft.id)
            .metadata(Array(repeating: Data([4, 2, 0]), count: 4))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let nftSerials = try XCTUnwrap(mintReceipt.serials)

        _ = try await TransferTransaction()
            .nftTransfer(nft.id.nft(nftSerials[0]), testEnv.operator.accountId, receiverAccount.id)
            .nftTransfer(nft.id.nft(nftSerials[1]), testEnv.operator.accountId, receiverAccount.id)
            .nftTransfer(nft.id.nft(nftSerials[2]), testEnv.operator.accountId, receiverAccount.id)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        await assertThrowsHErrorAsync(
            try await TokenRejectTransaction()
                .owner(receiverAccount.id)
                .addTokenId(nft.id)
                .nftIds([nft.id.nft(nftSerials[1]), nft.id.nft(nftSerials[2])])
                .freezeWith(testEnv.client)
                .sign(receiverAccountKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .accountAmountTransfersOnlyAllowedForFungibleCommon)
        }

        await assertThrowsHErrorAsync(
            try await TokenRejectTransaction()
                .owner(receiverAccount.id)
                .tokenIds([nft.id])
                .freezeWith(testEnv.client)
                .sign(receiverAccountKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .accountAmountTransfersOnlyAllowedForFungibleCommon)
        }

        addTeardownBlock {
            try await nft.delete(testEnv)
        }
    }

    internal func testTreasuryFail() async throws {
        let testEnv = try TestEnvironment.nonFree

        let ft = try await FungibleToken.create(testEnv, decimals: 3)

        await assertThrowsHErrorAsync(
            try await TokenRejectTransaction()
                .owner(testEnv.operator.accountId)
                .addTokenId(ft.id)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .accountIsTreasury)
        }

        let nft = try await Nft.create(testEnv)

        let mintReceipt = try await TokenMintTransaction()
            .tokenId(nft.id)
            .metadata(Array(repeating: Data([4, 2, 0]), count: 4))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let nftSerials = try XCTUnwrap(mintReceipt.serials)

        await assertThrowsHErrorAsync(
            try await TokenRejectTransaction()
                .owner(testEnv.operator.accountId)
                .addNftId(nft.id.nft(nftSerials[0]))
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .accountIsTreasury)
        }
    }

    internal func testInvalidSigFail() async throws {
        let testEnv = try TestEnvironment.nonFree

        let ft = try await FungibleToken.create(testEnv, decimals: 3)
        let randomKey = PrivateKey.generateEd25519()
        let receiverAccountKey = PrivateKey.generateEd25519()
        let receiverAccount = try await Account.create(testEnv, Key.single(receiverAccountKey.publicKey), 100)

        _ = try await TransferTransaction()
            .tokenTransfer(ft.id, testEnv.operator.accountId, -10)
            .tokenTransfer(ft.id, receiverAccount.id, 10)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        await assertThrowsHErrorAsync(
            try await TokenRejectTransaction()
                .owner(receiverAccount.id)
                .addTokenId(ft.id)
                .freezeWith(testEnv.client)
                .sign(randomKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        addTeardownBlock {
            try await ft.delete(testEnv)
        }
    }

    internal func testMissingTokenFail() async throws {
        let testEnv = try TestEnvironment.nonFree

        await assertThrowsHErrorAsync(
            try await TokenRejectTransaction()
                .owner(testEnv.operator.accountId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .transactionPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.transactionPreCheckStatus`")
                return
            }

            XCTAssertEqual(status, .emptyTokenReferenceList)
        }
    }

    internal func testTokenReferenceListSizeExceededFail() async throws {
        let testEnv = try TestEnvironment.nonFree

        let ft = try await FungibleToken.create(testEnv, decimals: 3)
        let nft = try await Nft.create(testEnv)
        let receiverAccountKey = PrivateKey.generateEd25519()
        let receiverAccount = try await Account.create(testEnv, Key.single(receiverAccountKey.publicKey), -1)

        let mintReceipt = try await TokenMintTransaction()
            .tokenId(nft.id)
            .metadata(Array(repeating: Data([9, 1, 6]), count: 10))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let nftSerials = try XCTUnwrap(mintReceipt.serials)

        _ = try await TransferTransaction()
            .tokenTransfer(ft.id, testEnv.operator.accountId, -10)
            .tokenTransfer(ft.id, receiverAccount.id, 10)
            .nftTransfer(nft.id.nft(nftSerials[0]), testEnv.operator.accountId, receiverAccount.id)
            .nftTransfer(nft.id.nft(nftSerials[1]), testEnv.operator.accountId, receiverAccount.id)
            .nftTransfer(nft.id.nft(nftSerials[2]), testEnv.operator.accountId, receiverAccount.id)
            .nftTransfer(nft.id.nft(nftSerials[3]), testEnv.operator.accountId, receiverAccount.id)
            .nftTransfer(nft.id.nft(nftSerials[4]), testEnv.operator.accountId, receiverAccount.id)
            .nftTransfer(nft.id.nft(nftSerials[5]), testEnv.operator.accountId, receiverAccount.id)
            .nftTransfer(nft.id.nft(nftSerials[6]), testEnv.operator.accountId, receiverAccount.id)
            .nftTransfer(nft.id.nft(nftSerials[7]), testEnv.operator.accountId, receiverAccount.id)
            .nftTransfer(nft.id.nft(nftSerials[8]), testEnv.operator.accountId, receiverAccount.id)
            .nftTransfer(nft.id.nft(nftSerials[9]), testEnv.operator.accountId, receiverAccount.id)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        await assertThrowsHErrorAsync(
            try await TokenRejectTransaction()
                .owner(receiverAccount.id)
                .addTokenId(ft.id)
                .nftIds([
                    nft.id.nft(nftSerials[0]), nft.id.nft(nftSerials[1]), nft.id.nft(nftSerials[2]),
                    nft.id.nft(nftSerials[3]), nft.id.nft(nftSerials[4]), nft.id.nft(nftSerials[5]),
                    nft.id.nft(nftSerials[6]), nft.id.nft(nftSerials[7]), nft.id.nft(nftSerials[8]),
                    nft.id.nft(nftSerials[9]),
                ])
                .freezeWith(testEnv.client)
                .sign(receiverAccountKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .tokenReferenceListSizeLimitExceeded)
        }

        addTeardownBlock {
            try await nft.delete(testEnv)
            try await ft.delete(testEnv)
        }
    }
}
