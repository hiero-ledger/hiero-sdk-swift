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

import Foundation
import Hiero
import SwiftDotenv

@main
internal enum Program {
    internal static func main() async throws {
        let env = try Dotenv.load()
        let client = try Client.forName(env.networkName)

        // Defaults the operator account ID and key such that all generated transactions will be paid for
        // by this account and be signed by this key
        client.setOperator(env.operatorAccountId, env.operatorKey)

        // Create Alice account
        let newKey = PrivateKey.generateEd25519()

        print("private key: \(newKey)")
        print("public key: \(newKey.publicKey)")

        // Create an account and stake to an acount ID
        // In this case we're staking to account ID 3 which happens to be
        // the account ID of node 0, we're only doing this as an example.
        // If you really want to stake to node 0, you should use
        // `.setStakedNodeId()` instead
        let newAccountId = try await AccountCreateTransaction()
            .key(.single(newKey.publicKey))
            .initialBalance(Hbar(10))
            .stakedAccountId("0.0.3")
            .execute(client)
            .getReceipt(client)
            .accountId!

        print("new account ID: \(newAccountId)")

        // Show the required key used to sign the account update transaction to
        // stake the accounts hbar i.e. the fee payer key and key to authorize
        // changes to the account should be different
        print("key required to update staking information: \(newKey.publicKey)")

        print("fee payer aka operator key: \(env.operatorKey.publicKey)")

        // Query the account info, it should show the staked account ID
        // to be 0.0.3 just like what we set it to
        var info = try await AccountInfoQuery()
            .accountId(newAccountId)
            .execute(client)

        print("staking info: \(String(describing: info.staking))")

        // Use the `AccountUpdateTransaction` to unstake the account's hbars
        //
        // If this succeeds then we should no longer have a staked account ID
        _ = try await AccountUpdateTransaction()
            .accountId(newAccountId)
            .clearStakedAccountId()
            .sign(newKey)
            .execute(client)
            .getReceipt(client)

        // Query the account info, it should show the staked account ID
        // to be `None` just like what we set it to
        info = try await AccountInfoQuery()
            .accountId(newAccountId)
            .execute(client)

        print("staking info: \(String(describing: info.staking))")
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
