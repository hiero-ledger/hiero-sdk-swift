// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero
import XCTest

internal final class TransferTransactionHooks: XCTestCase {

    internal func testHbarTransferWithPreTxHook() async throws {
        let testEnv = try TestEnvironment.nonFree

        // Create a test account
        let key = PrivateKey.generateEd25519()
        let receipt = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(key.publicKey))
            .initialBalance(10)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let accountId = try XCTUnwrap(receipt.accountId)

        // Create a simple hook call
        var hookCall = HookCall()
        hookCall = hookCall.hookId(1)
        var evmHookCall = EvmHookCall()
        evmHookCall = evmHookCall.data(Data([0x01, 0x02, 0x03]))
        evmHookCall = evmHookCall.gasLimit(100000)
        hookCall = hookCall.evmHookCall(evmHookCall)

        // Create transfer transaction with hook
        let transferTx = TransferTransaction()
            .hbarTransferWithPreTxHook(accountId, 1, hookCall)

        // Execute the transaction
        let response = try await transferTx.execute(testEnv.client)
        let transferReceipt = try await response.getReceipt(testEnv.client)

        XCTAssertEqual(transferReceipt.status, .success)
    }

    internal func testHbarTransferWithPrePostTxHook() async throws {
        let testEnv = try TestEnvironment.nonFree

        // Create a test account
        let key = PrivateKey.generateEd25519()
        let receipt = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(key.publicKey))
            .initialBalance(10)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let accountId = try XCTUnwrap(receipt.accountId)

        // Create a simple hook call
        var hookCall = HookCall()
        hookCall = hookCall.hookId(1)
        var evmHookCall = EvmHookCall()
        evmHookCall = evmHookCall.data(Data([0x01, 0x02, 0x03]))
        evmHookCall = evmHookCall.gasLimit(100000)
        hookCall = hookCall.evmHookCall(evmHookCall)

        // Create transfer transaction with hook
        let transferTx = TransferTransaction()
            .hbarTransferWithPrePostTxHook(accountId, 1, hookCall)

        // Execute the transaction
        let response = try await transferTx.execute(testEnv.client)
        let transferReceipt = try await response.getReceipt(testEnv.client)

        XCTAssertEqual(transferReceipt.status, .success)
    }

    internal func testTokenTransferWithPreTxHook() async throws {
        let testEnv = try TestEnvironment.nonFree

        // Create a test account
        let key = PrivateKey.generateEd25519()
        let receipt = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(key.publicKey))
            .initialBalance(10)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let accountId = try XCTUnwrap(receipt.accountId)

        // Create a token
        let tokenId = try await TokenCreateTransaction()
            .name("Test Token")
            .symbol("TT")
            .decimals(2)
            .initialSupply(1000)
            .treasuryAccountId(testEnv.operator.accountId)
            .adminKey(.single(testEnv.operator.privateKey.publicKey))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
            .tokenId!

        addTeardownBlock {
            _ = try await TokenDeleteTransaction(tokenId: tokenId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        }

        // Associate the account with the token
        _ = try await TokenAssociateTransaction(accountId: accountId, tokenIds: [tokenId])
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Create a simple hook call
        var hookCall = HookCall()
        hookCall = hookCall.hookId(1)
        var evmHookCall = EvmHookCall()
        evmHookCall = evmHookCall.data(Data([0x01, 0x02, 0x03]))
        evmHookCall = evmHookCall.gasLimit(100000)
        hookCall = hookCall.evmHookCall(evmHookCall)

        // Create transfer transaction with hook
        let transferTx = TransferTransaction()
            .tokenTransferWithPreTxHook(tokenId, accountId, 100, hookCall)

        // Execute the transaction
        let response = try await transferTx.execute(testEnv.client)
        let transferReceipt = try await response.getReceipt(testEnv.client)

        XCTAssertEqual(transferReceipt.status, .success)
    }

    internal func testNftTransferWithSenderHooks() async throws {
        let testEnv = try TestEnvironment.nonFree

        // Create test accounts
        let senderKey = PrivateKey.generateEd25519()
        let senderReceipt = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(senderKey.publicKey))
            .initialBalance(10)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let senderAccountId = try XCTUnwrap(senderReceipt.accountId)

        let receiverKey = PrivateKey.generateEd25519()
        let receiverReceipt = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(receiverKey.publicKey))
            .initialBalance(10)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let receiverAccountId = try XCTUnwrap(receiverReceipt.accountId)

        // Create an NFT token
        let tokenId = try await TokenCreateTransaction()
            .name("Test NFT")
            .symbol("TNFT")
            .tokenType(.nonFungibleUnique)
            .treasuryAccountId(testEnv.operator.accountId)
            .adminKey(.single(testEnv.operator.privateKey.publicKey))
            .supplyKey(.single(testEnv.operator.privateKey.publicKey))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
            .tokenId!

        addTeardownBlock {
            _ = try await TokenDeleteTransaction(tokenId: tokenId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        }

        // Associate accounts with the token
        _ = try await TokenAssociateTransaction(accountId: senderAccountId, tokenIds: [tokenId])
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await TokenAssociateTransaction(accountId: receiverAccountId, tokenIds: [tokenId])
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Mint an NFT
        let nftSerial = try await TokenMintTransaction(tokenId: tokenId)
            .metadata([Data("NFT Metadata".utf8)])
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
            .serials?.first!

        // Transfer NFT to sender
        _ = try await TransferTransaction()
            .nftTransfer(NftId(tokenId: tokenId, serial: nftSerial!), testEnv.operator.accountId, senderAccountId)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Create a simple hook call
        var hookCall = HookCall()
        hookCall = hookCall.hookId(1)
        var evmHookCall = EvmHookCall()
        evmHookCall = evmHookCall.data(Data([0x01, 0x02, 0x03]))
        evmHookCall = evmHookCall.gasLimit(100000)
        hookCall = hookCall.evmHookCall(evmHookCall)

        // Create transfer transaction with sender hook
        let transferTx = TransferTransaction()
            .nftTransferWithSenderHooks(
                NftId(tokenId: tokenId, serial: nftSerial!),
                senderAccountId,
                receiverAccountId,
                preTxSenderHook: hookCall
            )

        // Execute the transaction
        let response = try await transferTx.execute(testEnv.client)
        let transferReceipt = try await response.getReceipt(testEnv.client)

        XCTAssertEqual(transferReceipt.status, .success)
    }

    internal func testNftTransferWithReceiverHooks() async throws {
        let testEnv = try TestEnvironment.nonFree

        // Create test accounts
        let senderKey = PrivateKey.generateEd25519()
        let senderReceipt = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(senderKey.publicKey))
            .initialBalance(10)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let senderAccountId = try XCTUnwrap(senderReceipt.accountId)

        let receiverKey = PrivateKey.generateEd25519()
        let receiverReceipt = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(receiverKey.publicKey))
            .initialBalance(10)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let receiverAccountId = try XCTUnwrap(receiverReceipt.accountId)

        // Create an NFT token
        let tokenId = try await TokenCreateTransaction()
            .name("Test NFT")
            .symbol("TNFT")
            .tokenType(.nonFungibleUnique)
            .treasuryAccountId(testEnv.operator.accountId)
            .adminKey(.single(testEnv.operator.privateKey.publicKey))
            .supplyKey(.single(testEnv.operator.privateKey.publicKey))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
            .tokenId!

        addTeardownBlock {
            _ = try await TokenDeleteTransaction(tokenId: tokenId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        }

        // Associate accounts with the token
        _ = try await TokenAssociateTransaction(accountId: senderAccountId, tokenIds: [tokenId])
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await TokenAssociateTransaction(accountId: receiverAccountId, tokenIds: [tokenId])
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Mint an NFT
        let nftSerial = try await TokenMintTransaction(tokenId: tokenId)
            .metadata([Data("NFT Metadata".utf8)])
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
            .serials?.first!

        // Transfer NFT to sender
        _ = try await TransferTransaction()
            .nftTransfer(NftId(tokenId: tokenId, serial: nftSerial!), testEnv.operator.accountId, senderAccountId)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Create a simple hook call
        var hookCall = HookCall()
        hookCall = hookCall.hookId(1)
        var evmHookCall = EvmHookCall()
        evmHookCall = evmHookCall.data(Data([0x01, 0x02, 0x03]))
        evmHookCall = evmHookCall.gasLimit(100000)
        hookCall = hookCall.evmHookCall(evmHookCall)

        // Create transfer transaction with receiver hook
        let transferTx = TransferTransaction()
            .nftTransferWithReceiverHooks(
                NftId(tokenId: tokenId, serial: nftSerial!),
                senderAccountId,
                receiverAccountId,
                preTxReceiverHook: hookCall
            )

        // Execute the transaction
        let response = try await transferTx.execute(testEnv.client)
        let transferReceipt = try await response.getReceipt(testEnv.client)

        XCTAssertEqual(transferReceipt.status, .success)
    }

    internal func testNftTransferWithAllHooks() async throws {
        let testEnv = try TestEnvironment.nonFree

        // Create test accounts
        let senderKey = PrivateKey.generateEd25519()
        let senderReceipt = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(senderKey.publicKey))
            .initialBalance(10)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let senderAccountId = try XCTUnwrap(senderReceipt.accountId)

        let receiverKey = PrivateKey.generateEd25519()
        let receiverReceipt = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(receiverKey.publicKey))
            .initialBalance(10)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let receiverAccountId = try XCTUnwrap(receiverReceipt.accountId)

        // Create an NFT token
        let tokenId = try await TokenCreateTransaction()
            .name("Test NFT")
            .symbol("TNFT")
            .tokenType(.nonFungibleUnique)
            .treasuryAccountId(testEnv.operator.accountId)
            .adminKey(.single(testEnv.operator.privateKey.publicKey))
            .supplyKey(.single(testEnv.operator.privateKey.publicKey))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
            .tokenId!

        addTeardownBlock {
            _ = try await TokenDeleteTransaction(tokenId: tokenId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        }

        // Associate accounts with the token
        _ = try await TokenAssociateTransaction(accountId: senderAccountId, tokenIds: [tokenId])
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await TokenAssociateTransaction(accountId: receiverAccountId, tokenIds: [tokenId])
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Mint an NFT
        let nftSerial = try await TokenMintTransaction(tokenId: tokenId)
            .metadata([Data("NFT Metadata".utf8)])
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
            .serials?.first!

        // Transfer NFT to sender
        _ = try await TransferTransaction()
            .nftTransfer(NftId(tokenId: tokenId, serial: nftSerial!), testEnv.operator.accountId, senderAccountId)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Create hook calls
        var senderHookCall = HookCall()
        senderHookCall = senderHookCall.hookId(1)
        var senderEvmHookCall = EvmHookCall()
        senderEvmHookCall = senderEvmHookCall.data(Data([0x01, 0x02, 0x03]))
        senderEvmHookCall = senderEvmHookCall.gasLimit(100000)
        senderHookCall = senderHookCall.evmHookCall(senderEvmHookCall)

        var receiverHookCall = HookCall()
        receiverHookCall = receiverHookCall.hookId(2)
        var receiverEvmHookCall = EvmHookCall()
        receiverEvmHookCall = receiverEvmHookCall.data(Data([0x04, 0x05, 0x06]))
        receiverEvmHookCall = receiverEvmHookCall.gasLimit(100000)
        receiverHookCall = receiverHookCall.evmHookCall(receiverEvmHookCall)

        // Create transfer transaction with all hooks
        let transferTx = TransferTransaction()
            .nftTransferWithAllHooks(
                NftId(tokenId: tokenId, serial: nftSerial!),
                senderAccountId,
                receiverAccountId,
                preTxSenderHook: senderHookCall,
                preTxReceiverHook: receiverHookCall
            )

        // Execute the transaction
        let response = try await transferTx.execute(testEnv.client)
        let transferReceipt = try await response.getReceipt(testEnv.client)

        XCTAssertEqual(transferReceipt.status, .success)
    }

    internal func testApprovedTransferWithHooks() async throws {
        let testEnv = try TestEnvironment.nonFree

        // Create a test account
        let key = PrivateKey.generateEd25519()
        let receipt = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(key.publicKey))
            .initialBalance(10)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let accountId = try XCTUnwrap(receipt.accountId)

        // Create a simple hook call
        var hookCall = HookCall()
        hookCall = hookCall.hookId(1)
        var evmHookCall = EvmHookCall()
        evmHookCall = evmHookCall.data(Data([0x01, 0x02, 0x03]))
        evmHookCall = evmHookCall.gasLimit(100000)
        hookCall = hookCall.evmHookCall(evmHookCall)

        // Create approved transfer transaction with hook
        let transferTx = TransferTransaction()
            .approvedHbarTransferWithPreTxHook(accountId, 1, hookCall)

        // Execute the transaction
        let response = try await transferTx.execute(testEnv.client)
        let transferReceipt = try await response.getReceipt(testEnv.client)

        XCTAssertEqual(transferReceipt.status, .success)
    }
}
