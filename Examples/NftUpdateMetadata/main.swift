/*
 * ‌
 * Hedera Swift SDK
 *
 * Copyright (C) 2022 - 2024 Hedera Hashgraph, LLC
 *
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
 *
 */

import Foundation
import Hiero
import SwiftDotenv

@main
internal enum Program {

    private static let metadataKey: PrivateKey = PrivateKey.generateEd25519()
    private static let initialMetadata: Data = Data([1])
    private static let newMetadata: Data = Data([1, 2])

    internal static func main() async throws {
        let env = try Dotenv.load()
        let client = try Client.forName(env.networkName)

        // Defaults the operator account ID and key such that all generated transactions will be paid for
        // by this account and be signed by this key
        client.setOperator(env.operatorAccountId, env.operatorKey)

        // Demonstrate with an mutable token (with admin key)
        try await updateNftsMetadata(client, env, try getMutableTokenCreateTransaction(client, env))

        // Demonstrate with an immutable token (with metadata key)
        try await updateNftsMetadata(client, env, try getImmutableTokenCreateTransaction(client, env))

    }

    internal static func updateNftsMetadata(
        _ client: Client, _ env: Environment, _ tokenCreateTransaction: TokenCreateTransaction
    ) async throws {
        let tokenCreateResponse = try await tokenCreateTransaction.sign(env.operatorKey).execute(client)
        let tokenCreateReceipt = try await tokenCreateResponse.getReceipt(client)

        print("Status of token create transaction: \(tokenCreateReceipt.status)")

        let tokenId = tokenCreateReceipt.tokenId!
        print("Token id: \(tokenId)")

        let tokenInfo = try await TokenInfoQuery()
            .tokenId(tokenId)
            .execute(client)

        print("Token metadata key: \(tokenInfo.metadataKey!)")

        let tokenMintTransaction = TokenMintTransaction()
            .tokenId(tokenId)
            .metadata([initialMetadata])

        _ = tokenMintTransaction.metadata.map {
            print("Set metadata: \($0.bytes)")
        }

        let tokenMintReceipt = try await tokenMintTransaction.execute(client).getReceipt(client)

        print("Status of token mint transaction: \(tokenMintReceipt.status)")

        let nftSerials = tokenMintReceipt.serials!

        let accountCreateTransaction = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(env.operatorKey.publicKey))
            .maxAutomaticTokenAssociations(10)
            .execute(client)

        // Create an account to send the NFT to
        let newAccountId = try await accountCreateTransaction.getReceipt(client).accountId!

        // Transfer the Nft to the new account
        _ = try await TransferTransaction()
            .nftTransfer(tokenId.nft(nftSerials.first!), env.operatorAccountId, newAccountId)
            .execute(client)

        // Update metadata of Nft
        let tokenUpdateNftsTransaction = try TokenUpdateNftsTransaction()
            .tokenId(tokenId)
            .serials(nftSerials)
            .metadata(newMetadata)
            .freezeWith(client)

        print("Updated metadata: \(tokenUpdateNftsTransaction.metadata.bytes)")

        // Get receipt for update nfts metadata transaction
        let tokenUpdateNftsReceipt = try await tokenUpdateNftsTransaction.sign(metadataKey).execute(client).getReceipt(
            client)

        print("Status of token update nfts metadata transaction: \(tokenUpdateNftsReceipt.status)")

        // Check that metadata for the NFT was updated correctly
        let metadataList = try await getMetadataList(client, tokenId, nftSerials)

        _ = metadataList.map {
            print("Metadata after update: \($0.bytes)")
        }
    }

    internal static func getMutableTokenCreateTransaction(_ client: Client, _ env: Environment) throws
        -> TokenCreateTransaction
    {
        print("Creating a mutable token")

        return try TokenCreateTransaction()
            .name("ffff")
            .symbol("F")
            .tokenType(TokenType.nonFungibleUnique)
            .treasuryAccountId(env.operatorAccountId)
            .adminKey(.single(env.operatorKey.publicKey))
            .supplyKey(.single(env.operatorKey.publicKey))
            .metadataKey(.single(metadataKey.publicKey))
            .expirationTime(Timestamp.now + .hours(2))
            .freezeWith(client)
    }

    internal static func getImmutableTokenCreateTransaction(_ client: Client, _ env: Environment) throws
        -> TokenCreateTransaction
    {
        print("Creating a immutable token")

        return try TokenCreateTransaction()
            .name("ffff")
            .symbol("F")
            .tokenType(TokenType.nonFungibleUnique)
            .treasuryAccountId(env.operatorAccountId)
            .supplyKey(.single(env.operatorKey.publicKey))
            .metadataKey(.single(metadataKey.publicKey))
            .expirationTime(Timestamp.now + .hours(2))
            .freezeWith(client)
    }
}

func getMetadataList(_ client: Client, _ tokenId: TokenId, _ serials: [UInt64]) async throws -> [Data] {
    let metadataList: [Data] = try await withThrowingTaskGroup(
        of: Data.self,
        body: { group in
            var results = [Data]()

            // Iterate over serials, launching a new task for each
            for serial in serials {
                group.addTask {
                    let nftId = NftId(tokenId: tokenId, serial: UInt64(serial))
                    // Execute the query and return the result
                    return try await TokenNftInfoQuery().nftId(nftId).execute(client).metadata
                }
            }

            // Collect results from all tasks
            for try await result in group {
                results.append(result)
            }

            return results
        })

    return metadataList
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
