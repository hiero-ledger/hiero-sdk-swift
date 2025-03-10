// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero
import SwiftDotenv

@main
internal enum Program {
    internal static func main() async throws {
        let env = try Dotenv.load()
        let client = try Client.forName(env.networkName)

        client.setOperator(env.operatorAccountId, env.operatorKey)

        let privateKey1 = PrivateKey.generateEcdsa()
        let aliceId = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(privateKey1.publicKey))
            .initialBalance(Hbar(10))
            .maxAutomaticTokenAssociations(-1)
            .execute(client)
            .getReceipt(client)
            .accountId!

        let privateKey2 = PrivateKey.generateEcdsa()
        let bobId = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(privateKey2.publicKey))
            .maxAutomaticTokenAssociations(1)
            .execute(client)
            .getReceipt(client)
            .accountId!

        let privateKey3 = PrivateKey.generateEcdsa()
        let carolId = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(privateKey3.publicKey))
            .maxAutomaticTokenAssociations(0)
            .execute(client)
            .getReceipt(client)
            .accountId!

        let treasuryKey = PrivateKey.generateEcdsa()
        let treasuryAccountId = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(treasuryKey.publicKey))
            .initialBalance(Hbar(10))
            .execute(client)
            .getReceipt(client)
            .accountId!

        // Create FT and NFT and mint
        let tokenId = try await TokenCreateTransaction()
            .name("ffff")
            .symbol("F")
            .decimals(3)
            .initialSupply(100)
            .maxSupply(100)
            .treasuryAccountId(treasuryAccountId)
            .tokenSupplyType(.finite)
            .adminKey(.single(env.operatorKey.publicKey))
            .freezeKey(.single(env.operatorKey.publicKey))
            .supplyKey(.single(env.operatorKey.publicKey))
            .pauseKey(.single(env.operatorKey.publicKey))
            .expirationTime(.now + .hours(2))
            .freezeWith(client)
            .sign(treasuryKey)
            .execute(client)
            .getReceipt(client)
            .tokenId!

        let nftId = try await TokenCreateTransaction()
            .name("example NFT")
            .symbol("F")
            .maxSupply(10)
            .treasuryAccountId(treasuryAccountId)
            .tokenSupplyType(.finite)
            .tokenType(.nonFungibleUnique)
            .adminKey(.single(env.operatorKey.publicKey))
            .freezeKey(.single(env.operatorKey.publicKey))
            .supplyKey(.single(env.operatorKey.publicKey))
            .pauseKey(.single(env.operatorKey.publicKey))
            .expirationTime(.now + .hours(2))
            .freezeWith(client)
            .sign(treasuryKey)
            .execute(client)
            .getReceipt(client)
            .tokenId!

        _ = try await TokenMintTransaction()
            .tokenId(nftId)
            .metadata(Array(repeating: Data([9, 1, 6]), count: 4))
            .execute(client)
            .getReceipt(client)

        // Airdrop fungible tokens to all 3 accounts
        print("Airdropping tokens to all accounts")

        let txRecord = try await TokenAirdropTransaction()
            .tokenTransfer(tokenId, aliceId, 10)
            .tokenTransfer(tokenId, treasuryAccountId, -10)
            .tokenTransfer(tokenId, bobId, 10)
            .tokenTransfer(tokenId, treasuryAccountId, -10)
            .tokenTransfer(tokenId, carolId, 10)
            .tokenTransfer(tokenId, treasuryAccountId, -10)
            .freezeWith(client)
            .sign(treasuryKey)
            .execute(client)
            .getRecord(client)

        // Get the transaction record and see one pending airdrop (for carol)
        print("Pending airdrop length: \(txRecord.pendingAirdropRecords.count)")
        print("Pending airdrops: \(txRecord.pendingAirdropRecords.first!)")

        // Query to verify alice and bob received the airdrops and carol did not
        let aliceBalance = try await AccountBalanceQuery()
            .accountId(aliceId)
            .execute(client)

        let bobBalance = try await AccountBalanceQuery()
            .accountId(bobId)
            .execute(client)

        let carolBalance = try await AccountBalanceQuery()
            .accountId(carolId)
            .execute(client)

        print("Alice ft balance after airdrop: \(aliceBalance.tokenBalances[tokenId]!)")
        print("Bob ft balance after airdrop: \(bobBalance.tokenBalances[tokenId]!)")
        print("Carol ft balance after airdrop: \(String(describing:carolBalance.tokenBalances[tokenId]))")

        // Claim the airdrop for carol
        print("Claiming ft with Carol")

        _ = try await TokenClaimAirdropTransaction()
            .addPendingAirdropId(txRecord.pendingAirdropRecords[0].pendingAirdropId)
            .freezeWith(client)
            .sign(privateKey3)
            .execute(client)
            .getReceipt(client)

        let carolBalanceAfterClaim = try await AccountBalanceQuery()
            .accountId(carolId)
            .execute(client)

        print("Carol ft balance after airdrop: \(carolBalanceAfterClaim.tokenBalances[tokenId]!)")

        // Airdrop the NFTs to all three accounts
        print("Airdropping nfts")
        let nftTxRecord = try await TokenAirdropTransaction()
            .nftTransfer(nftId.nft(1), treasuryAccountId, aliceId)
            .nftTransfer(nftId.nft(2), treasuryAccountId, bobId)
            .nftTransfer(nftId.nft(3), treasuryAccountId, carolId)
            .freezeWith(client)
            .sign(treasuryKey)
            .execute(client)
            .getRecord(client)

        // Get the transaction record and verify two pending airdrops (for bob & carol)
        print("Pending airdrops length: \(nftTxRecord.pendingAirdropRecords.count)")
        print("Pending airdrops for Bob: \(nftTxRecord.pendingAirdropRecords[0])")
        print("Pending airdrops for Carol: \(nftTxRecord.pendingAirdropRecords[1])")

        // Query to verify alice received the airdrop and bob and carol did not
        let aliceNftBalance = try await AccountBalanceQuery()
            .accountId(aliceId)
            .execute(client)

        let bobNftBalance = try await AccountBalanceQuery()
            .accountId(bobId)
            .execute(client)

        let carolNftBalance = try await AccountBalanceQuery()
            .accountId(carolId)
            .execute(client)

        print("Alice nft balance after airdrop: \(aliceNftBalance.tokenBalances[nftId]!)")
        print("Bob nft balance after airdrop: \(String(describing:bobNftBalance.tokenBalances[nftId]))")
        print("Carol nft balance after airdrop: \(String(describing:carolNftBalance.tokenBalances[nftId]))")

        // Claim the airdrop for bob
        print("Claiming nft with Bob")
        _ = try await TokenClaimAirdropTransaction()
            .addPendingAirdropId(nftTxRecord.pendingAirdropRecords[0].pendingAirdropId)
            .freezeWith(client)
            .sign(privateKey2)
            .execute(client)
            .getReceipt(client)

        let bobNftBalanceAfterClaim = try await AccountBalanceQuery()
            .accountId(bobId)
            .execute(client)

        print("Bob nft balance after claim: \(bobNftBalanceAfterClaim.tokenBalances[nftId]!)")

        // Cancel the airdrop for carol
        print("Cancelling nft for Carol")
        _ = try await TokenCancelAirdropTransaction()
            .addPendingAirdropId(nftTxRecord.pendingAirdropRecords[1].pendingAirdropId)
            .freezeWith(client)
            .sign(treasuryKey)
            .execute(client)
            .getReceipt(client)

        let carolNftBalanceAfterCancel = try await AccountBalanceQuery()
            .accountId(carolId)
            .execute(client)

        print("Carol nft balance after cancel: \(String(describing:carolNftBalanceAfterCancel.tokenBalances[nftId]))")

        // Reject the NFT for bob
        print("Rejecting nft with Bob")
        _ = try await TokenRejectTransaction()
            .owner(bobId)
            .addNftId(nftId.nft(2))
            .freezeWith(client)
            .sign(privateKey2)
            .execute(client)
            .getReceipt(client)

        // Query to verify bob no longer has the NFT
        let bobNftBalanceAfterReject = try await AccountBalanceQuery()
            .accountId(bobId)
            .execute(client)

        print("Bob nft balance after reject: \(bobNftBalanceAfterReject.tokenBalances[nftId]!)")

        // Query to verify the NFT was returned to the Treasury
        let treasuryNftBalance = try await AccountBalanceQuery()
            .accountId(treasuryAccountId)
            .execute(client)

        print("Treasury nft balance after reject: \(treasuryNftBalance.tokenBalances[nftId]!)")

        // Reject the Fungible token for carol
        print("Rejecting ft with Carol")
        _ = try await TokenRejectTransaction()
            .owner(carolId)
            .addTokenId(tokenId)
            .freezeWith(client)
            .sign(privateKey3)
            .execute(client)
            .getReceipt(client)

        // Query to verify Carol no longer has the fungible tokens
        let carolFtBalanceAfterReject = try await AccountBalanceQuery()
            .accountId(carolId)
            .execute(client)

        print("Carol ft balance after reject: \(carolFtBalanceAfterReject.tokenBalances[tokenId]!)")

        // Query to verify Treasury received the rejected fungible tokens
        let treasuryFtBalance = try await AccountBalanceQuery()
            .accountId(treasuryAccountId)
            .execute(client)

        print("Treasury ft balance after reject: \(treasuryFtBalance.tokenBalances[tokenId]!)")

        print("Token airdrop example completed successfully")
    }
}

extension Environment {
    /// Account ID for the operator to use in this example.
    internal var operatorAccountId: AccountId {
        AccountId(self["OPERATOR_ID"]!.stringValue)!
    }

    /// Private key for the operator to use in this example.
    internal var operatorKey: PrivateKey {
        PrivateKey(self["OPERATOR_KEY"]!.stringValue)!
    }

    /// The name of the hedera network this example should be ran against.
    ///
    /// Testnet by default.
    internal var networkName: String {
        self["HEDERA_NETWORK"]?.stringValue ?? "testnet"
    }
}
