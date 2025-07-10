// SPDX-License-Identifier: Apache-2.0

import Hiero
import SwiftDotenv

@main
internal enum Program {
    internal static func main() async throws {
        let env = try Dotenv.load()
        let client = try Client.forName(env.networkName)

        client.setOperator(env.operatorAccountId, env.operatorKey)
        print(env.operatorAccountId)
        print(env.operatorKey)

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

    /// The name of the hedera network this example should be ran against.
    ///
    /// Testnet by default.
    internal var networkName: String {
        self["HEDERA_NETWORK"]?.stringValue ?? "testnet"
    }
}
