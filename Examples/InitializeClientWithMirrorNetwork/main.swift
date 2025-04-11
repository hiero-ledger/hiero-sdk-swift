// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroExampleUtilities

@main
internal enum Program {
    internal static func main() async throws {
        let env = try Environment.load()

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
