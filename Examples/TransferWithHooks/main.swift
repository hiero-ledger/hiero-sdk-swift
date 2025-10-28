// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero

/// Example demonstrating how to use hooks with transfer transactions.
///
/// This example shows how to:
/// 1. Set up prerequisites - create tokens and NFTs
/// 2. Demonstrate TransferTransaction API with hooks
/// 3. Execute different types of transfers with hooks
@main
struct TransferWithHooksExample {
    static func main() async throws {
        // Initialize the client
        let client = Client.forTestnet()

        // Create operator account
        let operatorKey = PrivateKey.generateEd25519()
        let operatorId = try AccountId.fromString("0.0.1234")  // Replace with your account ID

        client.setOperator(operatorId, operatorKey)

        print("Transfer Transaction Hooks Example Start!")

        /*
         * Step 1: Set up prerequisites - create tokens and NFTs
         */
        print("Setting up prerequisites...")

        // Create hook contract bytecode (simplified for Swift example)
        let hookBytecode = Data([
            0x60, 0x80, 0x60, 0x40, 0x52, 0x34, 0x80, 0x15, 0x61, 0x00, 0x10, 0x57, 0x60, 0x00, 0x80, 0xfd,
            0x5b, 0x50, 0x60, 0x04, 0x36, 0x10, 0x61, 0x00, 0x35, 0x60, 0x00, 0x35, 0x60, 0x00, 0x35, 0x60,
            0x00, 0x35, 0x60, 0x00, 0x35, 0x60, 0x00, 0x35, 0x60, 0x00, 0x35, 0x60, 0x00, 0x35, 0x60, 0x00,
            0x35, 0x60, 0x00, 0x35, 0x60, 0x00, 0x35, 0x60, 0x00, 0x35, 0x60, 0x00, 0x35, 0x60, 0x00, 0x35
        ])

        let hookContractResponse = try await ContractCreateTransaction()
            .adminKey(.single(operatorKey.publicKey))
            .gas(1_000_000)
            .bytecode(hookBytecode)
            .execute(client)

        let hookContractReceipt = try await hookContractResponse.getReceipt(client)
        guard let hookContractId = hookContractReceipt.contractId else {
            print("Failed to create hook contract!")
            return
        }

        print("Created hook contract: \(hookContractId)")

        // Create hook details
        var evmHookSpec = EvmHookSpec()
        evmHookSpec.contractId = hookContractId
        
        let lambdaHook = LambdaEvmHook(spec: evmHookSpec)
        
        let hookDetails = HookCreationDetails(
            hookExtensionPoint: .accountAllowanceHook,
            hookId: 1,
            lambdaEvmHook: lambdaHook
        )

        // Create sender account
        let senderKey = PrivateKey.generateEd25519()
        let senderResponse = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(senderKey.publicKey))
            .initialBalance(10)
            .addHook(hookDetails)
            .execute(client)
        
        let senderReceipt = try await senderResponse.getReceipt(client)
        guard let senderAccountId = senderReceipt.accountId else {
            print("Failed to create sender account!")
            return
        }

        print("Created sender account: \(senderAccountId)")

        // Create receiver account
        let receiverKey = PrivateKey.generateEd25519()
        let receiverResponse = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(receiverKey.publicKey))
            .maxAutomaticTokenAssociations(100)
            .initialBalance(10)
            .addHook(hookDetails)
            .execute(client)
        
        let receiverReceipt = try await receiverResponse.getReceipt(client)
        guard let receiverAccountId = receiverReceipt.accountId else {
            print("Failed to create receiver account!")
            return
        }

        print("Created receiver account: \(receiverAccountId)")

        // Create fungible token
        print("Creating fungible token...")
        let fungibleTokenResponse = try await TokenCreateTransaction()
            .name("Example Fungible Token")
            .symbol("EFT")
            .tokenType(.fungibleCommon)
            .decimals(2)
            .initialSupply(10000)
            .treasuryAccountId(senderAccountId)
            .adminKey(.single(senderKey.publicKey))
            .supplyKey(.single(senderKey.publicKey))
            .execute(client)

        let fungibleTokenReceipt = try await fungibleTokenResponse.getReceipt(client)
        guard let fungibleTokenId = fungibleTokenReceipt.tokenId else {
            print("Failed to create fungible token!")
            return
        }

        print("Created fungible token with ID: \(fungibleTokenId)")

        // Create NFT token
        print("Creating NFT token...")
        let nftTokenResponse = try await TokenCreateTransaction()
            .name("Example NFT Token")
            .symbol("ENT")
            .tokenType(.nonFungibleUnique)
            .treasuryAccountId(senderAccountId)
            .adminKey(.single(senderKey.publicKey))
            .supplyKey(.single(senderKey.publicKey))
            .execute(client)

        let nftTokenReceipt = try await nftTokenResponse.getReceipt(client)
        guard let nftTokenId = nftTokenReceipt.tokenId else {
            print("Failed to create NFT token!")
            return
        }

        print("Created NFT token with ID: \(nftTokenId)")

        // Mint NFT
        print("Minting NFT...")
        let nftMetadata = Data("Example NFT Metadata".utf8)
        let mintResponse = try await TokenMintTransaction()
            .tokenId(nftTokenId)
            .metadata([nftMetadata])
            .execute(client)

        let mintReceipt = try await mintResponse.getReceipt(client)
        guard let serialNumber = mintReceipt.serials?.first else {
            print("Failed to mint NFT!")
            return
        }

        let nftId = NftId(tokenId: nftTokenId, serial: serialNumber)
        print("Minted NFT with ID: \(nftId)")

        /*
         * Step 2: Demonstrate TransferTransaction API with hooks (demonstration only)
         */
        print("\n=== TransferTransaction with Hooks API Demonstration ===")

        // Create different hooks for different transfer types (for demonstration)
        print("Creating hook call objects (demonstration)...")

        // HBAR transfer with pre-tx allowance hook
        var hbarEvmHookCall = EvmHookCall()
        hbarEvmHookCall.data = Data([0x01, 0x02])
        hbarEvmHookCall.gasLimit = 20000

        let hbarHook = FungibleHookCall(
            hookCall: HookCall(hookId: 1, evmHookCall: hbarEvmHookCall),
            hookType: .preTxAllowanceHook
        )

        // NFT sender hook (pre-hook)
        var nftSenderEvmHookCall = EvmHookCall()
        nftSenderEvmHookCall.data = Data([0x03, 0x04])
        nftSenderEvmHookCall.gasLimit = 20000

        let nftSenderHook = NftHookCall(
            hookCall: HookCall(hookId: 1, evmHookCall: nftSenderEvmHookCall),
            hookType: .preHook
        )

        // NFT receiver hook (pre-hook)
        var nftReceiverEvmHookCall = EvmHookCall()
        nftReceiverEvmHookCall.data = Data([0x05, 0x06])
        nftReceiverEvmHookCall.gasLimit = 20000

        let nftReceiverHook = NftHookCall(
            hookCall: HookCall(hookId: 1, evmHookCall: nftReceiverEvmHookCall),
            hookType: .preHook
        )

        // Fungible token transfer with pre-post allowance hook
        var fungibleTokenEvmHookCall = EvmHookCall()
        fungibleTokenEvmHookCall.data = Data([0x07, 0x08])
        fungibleTokenEvmHookCall.gasLimit = 20000

        let fungibleTokenHook = FungibleHookCall(
            hookCall: HookCall(hookId: 1, evmHookCall: fungibleTokenEvmHookCall),
            hookType: .prePostTxAllowanceHook
        )

        // Build separate TransferTransactions with hooks (demonstration)
        print("Building separate TransferTransactions with hooks...")

        // Transaction 1: HBAR transfers with hook
        print("\n1. Building HBAR TransferTransaction with hook...")
        let hbarTransferResponse = try await TransferTransaction()
            .hbarTransferWithHook(senderAccountId, Hbar(-1), hbarHook)
            .hbarTransfer(receiverAccountId, Hbar(1))
            .execute(client)

        let hbarTransferReceipt = try await hbarTransferResponse.getReceipt(client)
        print("HBAR transfer completed with status: \(hbarTransferReceipt.status)")

        // Transaction 2: NFT transfer with sender and receiver hooks
        print("\n2. Building NFT TransferTransaction with hooks...")
        let nftTransferResponse = try await TransferTransaction()
            .nftTransferWithHooks(nftId, senderAccountId, receiverAccountId, nftSenderHook, nftReceiverHook)
            .execute(client)

        let nftTransferReceipt = try await nftTransferResponse.getReceipt(client)
        print("NFT transfer completed with status: \(nftTransferReceipt.status)")

        // Transaction 3: Fungible token transfers with hook
        print("\n3. Building Fungible Token TransferTransaction with hook...")
        let fungibleTransferResponse = try await TransferTransaction()
            .tokenTransferWithHook(fungibleTokenId, senderAccountId, -1000, fungibleTokenHook)
            .tokenTransfer(fungibleTokenId, receiverAccountId, 1000)
            .execute(client)

        let fungibleTransferReceipt = try await fungibleTransferResponse.getReceipt(client)
        print("Fungible token transfer completed with status: \(fungibleTransferReceipt.status)")

        print("\nAll TransferTransactions executed successfully with the following hook calls:")
        print("  - Transaction 1: HBAR transfer with pre-tx allowance hook")
        print("  - Transaction 2: NFT transfer with sender and receiver hooks")
        print("  - Transaction 3: Fungible token transfer with pre-post allowance hook")

        print("Transfer Transaction Hooks Example Complete!")
    }
}