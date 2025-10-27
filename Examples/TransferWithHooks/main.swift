// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero

/// Example demonstrating how to use hooks with transfer transactions.
/// 
/// This example shows how to:
/// 1. Create accounts
/// 2. Create a hook call
/// 3. Execute transfers with hooks
/// 4. Handle different types of hook calls
@main
struct TransferWithHooksExample {
    static func main() async throws {
        // Initialize the client
        let client = Client.forTestnet()
        
        // Create operator account
        let operatorKey = PrivateKey.generateEd25519()
        let operatorId = try AccountId.fromString("0.0.1234") // Replace with your account ID
        
        client.setOperator(operatorId, operatorKey)
        
        print("🚀 Transfer with Hooks Example")
        print("==============================")
        
        // Create test accounts
        print("\n📝 Creating test accounts...")
        
        let senderKey = PrivateKey.generateEd25519()
        let senderResponse = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(senderKey.publicKey))
            .initialBalance(10)
            .execute(client)
        let senderReceipt = try await senderResponse.getReceipt(client)
        let senderAccountId = senderReceipt.accountId!
        
        let receiverKey = PrivateKey.generateEd25519()
        let receiverResponse = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(receiverKey.publicKey))
            .initialBalance(5)
            .execute(client)
        let receiverReceipt = try await receiverResponse.getReceipt(client)
        let receiverAccountId = receiverReceipt.accountId!
        
        print("✅ Created sender account: \(senderAccountId)")
        print("✅ Created receiver account: \(receiverAccountId)")
        
        // Example 1: HBAR transfer with pre-transaction hook
        print("\n💰 Example 1: HBAR transfer with pre-transaction hook")
        
        var preTxHook = HookCall()
        preTxHook = preTxHook.hookId(1)
        var evmHookCall1 = EvmHookCall()
        evmHookCall1 = evmHookCall1.data(Data([0x01, 0x02, 0x03])) // Hook call data
        evmHookCall1 = evmHookCall1.gasLimit(100000) // Gas limit for hook execution
        preTxHook = preTxHook.evmHookCall(evmHookCall1)
        
        let hbarTransferTx = TransferTransaction()
            .hbarTransferWithPreTxHook(senderAccountId, 2, preTxHook)
        
        let hbarResponse = try await hbarTransferTx.execute(client)
        let hbarReceipt = try await hbarResponse.getReceipt(client)
        
        print("✅ HBAR transfer with hook completed: \(hbarReceipt.status)")
        
        // Example 2: HBAR transfer with pre-post-transaction hook
        print("\n💰 Example 2: HBAR transfer with pre-post-transaction hook")
        
        var prePostTxHook = HookCall()
        prePostTxHook = prePostTxHook.hookId(2)
        var evmHookCall2 = EvmHookCall()
        evmHookCall2 = evmHookCall2.data(Data([0x04, 0x05, 0x06]))
        evmHookCall2 = evmHookCall2.gasLimit(150000)
        prePostTxHook = prePostTxHook.evmHookCall(evmHookCall2)
        
        let hbarPrePostTx = TransferTransaction()
            .hbarTransferWithPrePostTxHook(senderAccountId, 1, prePostTxHook)
        
        let hbarPrePostResponse = try await hbarPrePostTx.execute(client)
        let hbarPrePostReceipt = try await hbarPrePostResponse.getReceipt(client)
        
        print("✅ HBAR transfer with pre-post hook completed: \(hbarPrePostReceipt.status)")
        
        // Example 3: Create a token and transfer with hooks
        print("\n🪙 Example 3: Token transfer with hooks")
        
        let tokenId = try await TokenCreateTransaction()
            .name("Hook Test Token")
            .symbol("HTT")
            .decimals(2)
            .initialSupply(1000)
            .treasuryAccountId(operatorId)
            .adminKey(.single(operatorKey.publicKey))
            .execute(client)
            .getReceipt(client)
            .tokenId!
        
        print("✅ Created token: \(tokenId)")
        
        // Associate accounts with the token
        _ = try await TokenAssociateTransaction(accountId: senderAccountId, tokenIds: [tokenId])
            .execute(client)
            .getReceipt(client)
        
        _ = try await TokenAssociateTransaction(accountId: receiverAccountId, tokenIds: [tokenId])
            .execute(client)
            .getReceipt(client)
        
        print("✅ Associated accounts with token")
        
        // Transfer tokens with hook
        var tokenHook = HookCall()
        tokenHook = tokenHook.hookId(3)
        var evmHookCall3 = EvmHookCall()
        evmHookCall3 = evmHookCall3.data(Data([0x07, 0x08, 0x09]))
        evmHookCall3 = evmHookCall3.gasLimit(200000)
        tokenHook = tokenHook.evmHookCall(evmHookCall3)
        
        let tokenTransferTx = TransferTransaction()
            .tokenTransferWithPreTxHook(tokenId, senderAccountId, 100, tokenHook)
        
        let tokenResponse = try await tokenTransferTx.execute(client)
        let tokenReceipt = try await tokenResponse.getReceipt(client)
        
        print("✅ Token transfer with hook completed: \(tokenReceipt.status)")
        
        // Example 4: NFT transfer with hooks
        print("\n🎨 Example 4: NFT transfer with hooks")
        
        let nftTokenId = try await TokenCreateTransaction()
            .name("Hook Test NFT")
            .symbol("HTNFT")
            .tokenType(.nonFungibleUnique)
            .treasuryAccountId(operatorId)
            .adminKey(.single(operatorKey.publicKey))
            .supplyKey(.single(operatorKey.publicKey))
            .execute(client)
            .getReceipt(client)
            .tokenId!
        
        print("✅ Created NFT token: \(nftTokenId)")
        
        // Associate accounts with the NFT token
        _ = try await TokenAssociateTransaction(accountId: senderAccountId, tokenIds: [nftTokenId])
            .execute(client)
            .getReceipt(client)
        
        _ = try await TokenAssociateTransaction(accountId: receiverAccountId, tokenIds: [nftTokenId])
            .execute(client)
            .getReceipt(client)
        
        // Mint an NFT
        let nftSerial = try await TokenMintTransaction(tokenId: nftTokenId)
            .metadata([Data("Hook Test NFT Metadata".utf8)])
            .execute(client)
            .getReceipt(client)
            .serials?.first!
        
        print("✅ Minted NFT with serial: \(nftSerial!)")
        
        // Transfer NFT to sender first
        _ = try await TransferTransaction()
            .nftTransfer(NftId(tokenId: nftTokenId, serial: nftSerial!), operatorId, senderAccountId)
            .execute(client)
            .getReceipt(client)
        
        // Transfer NFT with sender hook
        var senderHook = HookCall()
        senderHook = senderHook.hookId(4)
        var evmHookCall4 = EvmHookCall()
        evmHookCall4 = evmHookCall4.data(Data([0x0A, 0x0B, 0x0C]))
        evmHookCall4 = evmHookCall4.gasLimit(250000)
        senderHook = senderHook.evmHookCall(evmHookCall4)
        
        let nftTransferTx = TransferTransaction()
            .nftTransferWithSenderHooks(
                NftId(tokenId: nftTokenId, serial: nftSerial!),
                senderAccountId,
                receiverAccountId,
                preTxSenderHook: senderHook
            )
        
        let nftResponse = try await nftTransferTx.execute(client)
        let nftReceipt = try await nftResponse.getReceipt(client)
        
        print("✅ NFT transfer with sender hook completed: \(nftReceipt.status)")
        
        // Example 5: NFT transfer with receiver hook
        print("\n🎨 Example 5: NFT transfer with receiver hook")
        
        var receiverHook = HookCall()
        receiverHook = receiverHook.hookId(5)
        var evmHookCall5 = EvmHookCall()
        evmHookCall5 = evmHookCall5.data(Data([0x0D, 0x0E, 0x0F]))
        evmHookCall5 = evmHookCall5.gasLimit(300000)
        receiverHook = receiverHook.evmHookCall(evmHookCall5)
        
        let nftReceiverTx = TransferTransaction()
            .nftTransferWithReceiverHooks(
                NftId(tokenId: nftTokenId, serial: nftSerial!),
                receiverAccountId,
                senderAccountId,
                preTxReceiverHook: receiverHook
            )
        
        let nftReceiverResponse = try await nftReceiverTx.execute(client)
        let nftReceiverReceipt = try await nftReceiverResponse.getReceipt(client)
        
        print("✅ NFT transfer with receiver hook completed: \(nftReceiverReceipt.status)")
        
        // Example 6: NFT transfer with all hooks
        print("\n🎨 Example 6: NFT transfer with all hooks")
        
        var allSenderHook = HookCall()
        allSenderHook = allSenderHook.hookId(6)
        var evmHookCall6 = EvmHookCall()
        evmHookCall6 = evmHookCall6.data(Data([0x10, 0x11, 0x12]))
        evmHookCall6 = evmHookCall6.gasLimit(350000)
        allSenderHook = allSenderHook.evmHookCall(evmHookCall6)
        
        var allReceiverHook = HookCall()
        allReceiverHook = allReceiverHook.hookId(7)
        var evmHookCall7 = EvmHookCall()
        evmHookCall7 = evmHookCall7.data(Data([0x13, 0x14, 0x15]))
        evmHookCall7 = evmHookCall7.gasLimit(400000)
        allReceiverHook = allReceiverHook.evmHookCall(evmHookCall7)
        
        let nftAllHooksTx = TransferTransaction()
            .nftTransferWithAllHooks(
                NftId(tokenId: nftTokenId, serial: nftSerial!),
                senderAccountId,
                receiverAccountId,
                preTxSenderHook: allSenderHook,
                preTxReceiverHook: allReceiverHook
            )
        
        let nftAllHooksResponse = try await nftAllHooksTx.execute(client)
        let nftAllHooksReceipt = try await nftAllHooksResponse.getReceipt(client)
        
        print("✅ NFT transfer with all hooks completed: \(nftAllHooksReceipt.status)")
        
        // Cleanup
        print("\n🧹 Cleaning up...")
        
        _ = try await AccountDeleteTransaction()
            .accountId(senderAccountId)
            .transferAccountId(operatorId)
            .execute(client)
            .getReceipt(client)
        
        _ = try await AccountDeleteTransaction()
            .accountId(receiverAccountId)
            .transferAccountId(operatorId)
            .execute(client)
            .getReceipt(client)
        
        _ = try await TokenDeleteTransaction(tokenId: tokenId)
            .execute(client)
            .getReceipt(client)
        
        _ = try await TokenDeleteTransaction(tokenId: nftTokenId)
            .execute(client)
            .getReceipt(client)
        
        print("✅ Cleanup completed")
        print("\n🎉 Transfer with Hooks Example completed successfully!")
    }
}
