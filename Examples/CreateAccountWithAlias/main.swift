/*
 * ‌
 * Hedera Swift SDK
 * ​
 * Copyright (C) 2022 - 2025 Hedera Hashgraph, LLC
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

import Foundation
import Hiero
import SwiftDotenv

@main
internal enum Program {
    internal static func main() async throws {
        print("Starting Example")
        let env = try Dotenv.load()
        let client = try Client.forName(env.networkName)

        client.setOperator(env.operatorAccountId, env.operatorKey)
        // Creates a Hedera account with an alias using an ECDSA key.
        try await createAccountWithAlias(client)
        // Creates a Hedera account with both ED25519 and ECDSA keys.
        try await createAccountWithBothKeys(client)
        // Creates a Hedera account without an alias.
        try await createAccountWithoutAlias(client)

        print("Example finished")
    }

    internal static func createAccountWithAlias(_ client: Client) async throws {
        print("Creating account with alias")

        // Step 1:
        // Create a new ECDSA key
        let privateKey = PrivateKey.generateEcdsa()

        // Step 2:
        // Extract the ECDSA public key and generate EVM address
        let publicKey = privateKey.publicKey
        let evmAddress = publicKey.toEvmAddress()!

        // Step 3:
        // Create the account with an alias
        let accountId = try await AccountCreateTransaction()
            .keyWithAlias(privateKey)
            .freezeWith(client)
            .sign(privateKey)
            .execute(client)
            .getReceipt(client)
            .accountId!

        // Step 4:
        // Query account info
        let info = try await AccountInfoQuery()
            .accountId(accountId)
            .execute(client)

        print("Initial EVM address: \(evmAddress) is the same as \(info.contractAccountId)")
    }

    // Creates an account with an alias and a key
    internal static func createAccountWithBothKeys(_ client: Client) async throws {
        print("Creating account with an alias and a key")

        // Step 1:
        // Create a new ECDSA key and Ed25519 key
        let ed25519Key = PrivateKey.generateEd25519()
        let ecdsaKey = PrivateKey.generateEcdsa()

        // Step 2:
        // Extract the ECDSA public key and generate EVM address
        let evmAddress = ecdsaKey.publicKey.toEvmAddress()!

        // Step 3:
        // Create the account with both keys. Transaction needs to be signed
        // by both keys.
        let accountId = try await AccountCreateTransaction()
            .keyWithAlias(.single(ed25519Key.publicKey), ecdsaKey)
            .freezeWith(client)
            .sign(ed25519Key)
            .sign(ecdsaKey)
            .execute(client)
            .getReceipt(client)
            .accountId!

        // Step 4:
        // Query account info
        let info = try await AccountInfoQuery()
            .accountId(accountId)
            .execute(client)

        print("Account's key: \(info.key) is the same as \(ed25519Key.publicKey)")
        print("Initial EVM address: \(evmAddress) is the same as \(info.contractAccountId)")
    }

    // Creates an account without an alias.
    internal static func createAccountWithoutAlias(_ client: Client) async throws {
        print("Creating account without an alias")

        // Step 1:
        // Create a new ECDSA key
        let privateKey = PrivateKey.generateEcdsa()

        // Step 2:
        // Create an account without an alias.
        let accountId = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(privateKey.publicKey))
            .freezeWith(client)
            .sign(privateKey)
            .execute(client)
            .getReceipt(client)
            .accountId!

        // Step 3:
        // Query account info
        let info = try await AccountInfoQuery()
            .accountId(accountId)
            .execute(client)

        let isZeroAddress = isZeroAddress(try info.contractAccountId.bytes)

        print("Account's key: \(info.key) is the same as \(privateKey.publicKey)")
        print("Account has no alias: \(isZeroAddress)")
    }

    // Checks if an address is a zero address (all first 12 bytes are zero)
    internal static func isZeroAddress(_ address: [UInt8]) -> Bool {
        // Check first 12 bytes are all zero
        for byte in address[..<12] where byte != 0 {
            return false
        }
        return true
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
