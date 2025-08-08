
import Hiero
import SwiftDotenv

@main
internal enum Program {
    internal static func main() async throws {
        let env = try Dotenv.load()
        let client = try Client.forName(env.networkName)

        client.setOperator(env.operatorAccountId, env.operatorKey)

        let newKey = PrivateKey.generateEd25519()

        print("private key = \(newKey)")
        print("public key = \(newKey.publicKey)")

        let response = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(newKey.publicKey))
            .initialBalance(5)
            .execute(client)

        let receipt = try await response.getReceipt(client)
        let newAccountId = receipt.accountId!

        print("account address = \(newAccountId)")
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
// SPDX-License-Identifier: Apache-2.0

import Hiero
import SwiftDotenv

/// Example program to create a new Hedera account using the Hiero SDK.
///
/// This script demonstrates:
/// 1. Loading environment variables for network and operator credentials.
/// 2. Initializing a client for the target network.
/// 3. Generating a new Ed25519 key pair.
/// 4. Creating a new account with the generated public key and an initial balance.
/// 5. Printing the new account's ID and the generated keys.
@main
internal enum Program {
    internal static func main() async throws {
        // Load environment variables from .env file
        let env = try Dotenv.load()

        // Initialize the client for the specified network
        let client = try Client.forName(env.networkName)

        // Set the operator (payer) for transactions
        client.setOperator(env.operatorAccountId, env.operatorKey)

        // Generate a new Ed25519 private/public key pair
        let newKey = PrivateKey.generateEd25519()

        print("private key = \(newKey)")
        print("public key = \(newKey.publicKey)")

        // Create a new account with the generated public key and initial balance of 5 hbars
        let response = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(newKey.publicKey))
            .initialBalance(5)
            .execute(client)

        // Get the receipt and extract the new account ID
        let receipt = try await response.getReceipt(client)
        let newAccountId = receipt.accountId!

        print("account address = \(newAccountId)")
    }
}

extension Environment {
    /// Account ID for the operator to use in this example.
    /// Reads from the OPERATOR_ID environment variable.
    internal var operatorAccountId: AccountId {
        AccountId(self["OPERATOR_ID"]!.stringValue)!
    }

    /// Private key for the operator to use in this example.
    /// Reads from the OPERATOR_KEY environment variable.
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
