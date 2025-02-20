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
import SwiftDotenv

@main
internal enum Program {
    internal static func main() async throws {
        let env = try Dotenv.load()
        let client = try Client.forName(env.networkName)

        client.setOperator(env.operatorAccountId, env.operatorKey)

        let user1Key = PrivateKey.generateEd25519()
        let user2Key = PrivateKey.generateEd25519()

        print("private key for user 1 = \(user1Key)")
        print("public key for user 1 = \(user1Key.publicKey)")
        print("private key for user 2 = \(user2Key)")
        print("public key for user 2 = \(user2Key.publicKey)")

        // create a multi-sig account
        let keylist = KeyList(keys: [.single(user1Key.publicKey), .single(user2Key.publicKey)])

        let createAccountTransaction = try await AccountCreateTransaction()
            .initialBalance(2)
            .key(.keyList(keylist))
            .execute(client)

        let accountId = try await createAccountTransaction.getReceipt(client).accountId!

        print("account id = \(accountId)")

        // create a transfer from new account to 0.0.3
        let transferTransaction = TransferTransaction()

        try transferTransaction
            .nodeAccountIds([AccountId(num: 3)])
            .hbarTransfer(accountId, Hbar(-1))
            .hbarTransfer(AccountId(num: 3), Hbar(1))
            .freezeWith(client)

        // convert transaction to bytes to send to signatories
        let transactionBytes = try transferTransaction.toBytes()
        let transactionToExecute = try Transaction.fromBytes(transactionBytes)

        // ask users to sign and return signature
        let user1Signature = try user1Key.signTransaction(Transaction.fromBytes(transactionBytes))
        let user2Signature = try user2Key.signTransaction(Transaction.fromBytes(transactionBytes))

        // recreate the transaction from bytes
        try transactionToExecute.signWithOperator(client)
        transactionToExecute.addSignature(user1Key.publicKey, user1Signature)
        transactionToExecute.addSignature(user2Key.publicKey, user2Signature)

        let result = try await transactionToExecute.execute(client)
        let receipt = try await result.getReceipt(client)
        print("\(receipt.status)")
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
