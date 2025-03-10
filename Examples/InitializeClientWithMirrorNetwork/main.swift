// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroExampleUtilities
import SwiftDotenv

@main
internal enum Program {
    internal static func main() async throws {
        let env = try Dotenv.load()

        /*
         * Step 0: Create and Configure the Client
         */
        let client = try await Client.forMirrorNetwork(["testnet.mirrornode.hedera.com:443"])

        // Payer and signer for all transactions
        client.setOperator(env.operatorAccountId, env.operatorKey)

        /*
        * Step 1: Generate ed25519 keypair
        */
        print("Generating ed25519 keypair...")
        let privateKey = PrivateKey.generateEd25519()

        /*
        * Step 2: Create an account
        */
        let aliceId = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(privateKey.publicKey))
            .initialBalance(Hbar(5))
            .execute(client)
            .getReceipt(client)
            .accountId!

        print("Alice's account ID: \(aliceId)")
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
