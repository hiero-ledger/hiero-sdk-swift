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

        // Defaults the operator account ID and key such that all generated
        // transactions will be paid for by this account and be signed by this key
        client.setOperator(env.operatorAccountId, env.operatorKey)

        // Demonstrate with an mutable token (with admin key)
        try await updateMutableTokenMetadata(client, env)

        // Demonstrate with an immutable token (with metadata key)
        try await updateImmutableTokenMetadata(client, env)

    }

    internal static func updateMutableTokenMetadata(_ client: Client, _ env: Environment) async throws {
        print("Creating a mutable token")

        // Note: The same flow can be executed with a TokenType.NON_FUNGIBLE_UNIQUE (i.e. HIP-765)
        let tokenId = try await TokenCreateTransaction()
            .name("ffff")
            .symbol("F")
            .tokenType(TokenType.fungibleCommon)
            .decimals(3)
            .initialSupply(1_000_000)
            .treasuryAccountId(env.operatorAccountId)
            .adminKey(.single(env.operatorKey.publicKey))
            .metadata(initialMetadata)
            .expirationTime(Timestamp.now + .hours(2))
            .execute(client)
            .getReceipt(client)
            .tokenId!

        print("Created a mutable token: \(tokenId)")

        let tokenInfoAfterCreation = try await TokenInfoQuery()
            .tokenId(tokenId)
            .execute(client)

        print("Mutable token's metadata after creation: \(tokenInfoAfterCreation.metadata.bytes)")

        // Update token's metadata
        _ = try await TokenUpdateTransaction()
            .tokenId(tokenId)
            .metadata(newMetadata)
            .execute(client)
            .getReceipt(client)

        let tokenInfoAfterMetadataUpdate = try await TokenInfoQuery()
            .tokenId(tokenId)
            .execute(client)

        // check that metadata was updated correctly
        print("Mutable token's metadata after update: \(tokenInfoAfterMetadataUpdate.metadata.bytes)")
    }

    internal static func updateImmutableTokenMetadata(_ client: Client, _ env: Environment) async throws {
        print("Creating a immutable token")

        let metadataKey: PrivateKey = PrivateKey.generateEd25519()

        // Note: The same flow can be executed with a TokenType.NON_FUNGIBLE_UNIQUE (i.e. HIP-765)
        let tokenId = try await TokenCreateTransaction()
            .name("ffff")
            .symbol("F")
            .tokenType(TokenType.fungibleCommon)
            .treasuryAccountId(env.operatorAccountId)
            .decimals(3)
            .initialSupply(100000)
            .metadataKey(.single(metadataKey.publicKey))
            .expirationTime(Timestamp.now + .hours(2))
            .metadata(initialMetadata)
            .execute(client)
            .getReceipt(client)
            .tokenId!

        print("Created a immutable token: \(tokenId)")

        let tokenInfoAfterCreation = try await TokenInfoQuery()
            .tokenId(tokenId)
            .execute(client)

        print("tokenInfo metadatakey: \(tokenInfoAfterCreation.metadataKey!)")

        // check that metadata was set correctly
        print("Immutable token's metadata after creation: \(tokenInfoAfterCreation.metadata.bytes)")

        // Update token's metadata
        _ = try await TokenUpdateTransaction()
            .tokenId(tokenId)
            .metadata(newMetadata)
            .freezeWith(client)
            .sign(metadataKey)
            .execute(client)
            .getReceipt(client)

        let tokenInfoAfterMetadataUpdate = try await TokenInfoQuery()
            .tokenId(tokenId)
            .execute(client)

        // check that metadata was updated correctly
        print("Immutable token's metadata after update: \(tokenInfoAfterMetadataUpdate.metadata.bytes)")
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
