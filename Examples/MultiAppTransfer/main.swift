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

        client.setOperator(env.operatorAccountId, env.operatorKey)

        // the exchange should possess this key, we're only generating it for demonstration purposes
        let exchangeKey = PrivateKey.generateEd25519()
        // this is the only key we should actually possess
        let userKey = PrivateKey.generateEd25519()

        // the exchange creates an account for the user to transfer funds to
        let exchangeAccountId = try await AccountCreateTransaction()
            // the exchange only accepts transfers that it validates through a side channel (e.g. REST API)
            .receiverSignatureRequired(true)
            .key(.single(exchangeKey.publicKey))
            // The owner key has to sign this transaction
            // when receiver_signature_required is true
            .freezeWith(client)
            .sign(exchangeKey)
            .execute(client)
            .getReceipt(client)
            .accountId!

        // for the purpose of this example we create an account for
        // the user with a balance of 5 h
        let userAccountId = try await AccountCreateTransaction()
            .initialBalance(Hbar(5))
            .key(.single(userKey.publicKey))
            .execute(client)
            .getReceipt(client)
            .accountId!

        // next we make a transfer from the user account to the
        // exchange account, this requires signing by both parties
        let transferTxn = TransferTransaction()

        try transferTxn
            .hbarTransfer(userAccountId, Hbar(-2))
            .hbarTransfer(exchangeAccountId, Hbar(2))
            // the exchange-provided memo required to validate the transaction
            .transactionMemo("https://some-exchange.com/user1/account1")
            // NOTE: to manually sign, you must freeze the Transaction first
            .freezeWith(client)
            .sign(userKey)

        // the exchange must sign the transaction in order for it to be accepted by the network
        // assume this is some REST call to the exchange API server
        let signedTxnBytes = try exchangeSignsTransaction(exchangeKey, transferTxn.toBytes())

        // parse the transaction bytes returned from the exchange
        let signedTransferTxn = try Transaction.fromBytes(signedTxnBytes) as! TransferTransaction

        // get the amount we are about to transfer
        // we built this with +2, -2 (which we might see in any order)
        let transferAmount = signedTransferTxn.hbarTransfers.values.first.map { $0 < 0 ? -$0 : $0 }

        print("about to transfer \(String(describing: transferAmount))...")

        // we now execute the signed transaction and wait for it to be accepted
        let transactionResponse = try await signedTransferTxn.execute(client)

        // (important!) wait for consensus by querying for the receipt
        _ = try await transactionResponse.getReceipt(client)

        let senderBalanceAfter = try await AccountBalanceQuery()
            .accountId(userAccountId)
            .execute(client)
            .hbars

        let receiptBalanceAfter = try await AccountBalanceQuery()
            .accountId(exchangeAccountId)
            .execute(client)
            .hbars

        print("\(userAccountId) balance = \(senderBalanceAfter)")
        print("\(exchangeAccountId) balance = \(receiptBalanceAfter)")
    }

    private static func exchangeSignsTransaction(
        _ exchangeKey: PrivateKey,
        _ transactionData: Data
    ) throws -> Data {
        try Transaction.fromBytes(transactionData)
            .sign(exchangeKey)
            .toBytes()
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
