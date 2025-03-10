// SPDX-License-Identifier: Apache-2.0

import Hiero
import SwiftDotenv

@main
internal enum Program {
    internal static func main() async throws {
        let env = try Dotenv.load()
        let client = try Client.forName(env.networkName)

        client.setOperator(env.operatorAccountId, env.operatorKey)

        // Generate three new ed25519 private, public key pairs.
        // You do not need the private keys to create the Threshold Key List,
        // you only need the public keys, and if you're doing things correctly,
        // you probably shouldn't have these private keys.
        let privateKeys = [
            PrivateKey.generateEd25519(),
            PrivateKey.generateEd25519(),
            PrivateKey.generateEd25519(),
        ]

        print("public keys:")
        for key in privateKeys {
            print("\(key.publicKey)")
        }

        // require 2 of the 3 keys we generated to sign on anything modifying this account
        let transactionKey = KeyList(
            keys: privateKeys.map { .single($0.publicKey) },
            threshold: 2
        )

        let transactionResponse = try await AccountCreateTransaction()
            .keyWithoutAlias(.keyList(transactionKey))
            .initialBalance(Hbar(10))
            .execute(client)

        // This will wait for the receipt to become available
        let receipt = try await transactionResponse.getReceipt(client)

        let newAccountId = receipt.accountId!

        print("account = \(newAccountId)")

        let transferTransactionResponse = try await TransferTransaction()
            .hbarTransfer(newAccountId, Hbar(-10))
            .hbarTransfer(AccountId(num: 3), Hbar(10))
            // we sign with 2 of the 3 keys
            .sign(privateKeys[0])
            .sign(privateKeys[1])
            .execute(client)

        // (important!) wait for the transfer to go to consensus
        _ = try await transferTransactionResponse.getReceipt(client)

        let balanceAfter = try await AccountBalanceQuery()
            .accountId(newAccountId)
            .execute(client)
            .hbars

        print("account balance after transfer: \(balanceAfter)")
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
