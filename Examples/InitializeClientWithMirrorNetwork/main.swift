/*
 * ‌
 * Hedera Swift SDK
 * ​
 * Copyright (C) 2022 - 2024 Hedera Hashgraph, LLC
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
            .key(.single(privateKey.publicKey))
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
