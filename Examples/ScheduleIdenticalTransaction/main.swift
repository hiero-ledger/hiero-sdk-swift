// SPDX-License-Identifier: Apache-2.0

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

        print("threshold key example")
        print("keys:")

        var privateKeys: [PrivateKey] = []
        var publicKeys: [PublicKey] = []
        var clients: [Client] = []
        var accounts: [AccountId] = []

        for i in 0..<3 {
            let privateKey = PrivateKey.generateEd25519()
            let publicKey = privateKey.publicKey

            print("key #\(i)")
            print("private key: \(privateKey)")
            print("public key: \(publicKey)")

            let receipt = try await AccountCreateTransaction()
                .keyWithoutAlias(.single(publicKey))
                .initialBalance(Hbar(1))
                .execute(client)
                .getReceipt(client)

            let accountId = receipt.accountId!

            let client = try Client.forName(env.networkName)

            client.setOperator(accountId, privateKey)

            privateKeys.append(privateKey)
            publicKeys.append(publicKey)
            clients.append(client)
            accounts.append(accountId)
            print("account = \(accountId)")
        }

        let keyList = KeyList(keys: publicKeys.map(Key.single), threshold: 2)

        // We are using all of these keys, so the scheduled transaction doesn't automatically go through
        // It works perfectly fine with just one key
        // The key that must sign each transfer out of the account. If receiverSigRequired is true, then
        // it must also sign any transfer into the account.
        let thresholdAccount = try await AccountCreateTransaction()
            .keyWithoutAlias(.keyList(keyList))
            .initialBalance(Hbar(10))
            .execute(client)
            .getReceipt(client)
            .accountId!

        print("threshold account = \(thresholdAccount)")

        var scheduleId: ScheduleId?

        for (loopClient, operatorId) in zip(clients, accounts) {
            // Each loopClient creates an identical transaction, sending 1 hbar to each of the created accounts,
            // sent from the threshold Account
            let transaction = TransferTransaction()
            for account in accounts {
                transaction.hbarTransfer(account, Hbar(1))
            }

            transaction.hbarTransfer(thresholdAccount, Hbar(-3))

            let scheduledTransaction = ScheduleCreateTransaction()

            scheduledTransaction.scheduledTransaction(transaction)

            scheduledTransaction.payerAccountId(thresholdAccount)

            let response = try await scheduledTransaction.execute(loopClient)

            let loopReceipt = try await TransactionReceiptQuery()
                .transactionId(response.transactionId)
                .nodeAccountIds([response.nodeAccountId])
                .execute(loopClient)

            print(
                "operator [\(operatorId)]: scheduleId = \(String(describing: loopReceipt.scheduleId))"
            )

            // Save the schedule ID, so that it can be asserted for each loopClient submission
            scheduleId = scheduleId ?? loopReceipt.scheduleId!

            if scheduleId != loopReceipt.scheduleId {
                print(
                    "invalid generated schedule id, expected \(scheduleId!), got \(String(describing: loopReceipt.scheduleId))"
                )
            }

            // If the status return by the receipt is related to already created, execute a schedule sign transaction
            if loopReceipt.status == Status.identicalScheduleAlreadyCreated {
                let signResponse = try await ScheduleSignTransaction()
                    .scheduleId(scheduleId!)
                    .nodeAccountIds([response.nodeAccountId])
                    .execute(loopClient)

                let signReceipt = try await TransactionReceiptQuery()
                    .transactionId(signResponse.transactionId)
                    .execute(client)

                if signReceipt.status != .success && signReceipt.status != .scheduleAlreadyExecuted {
                    print(
                        "Bad status while getting receipt of schedule sign with operator \(operatorId): \(signReceipt.status)"
                    )

                    return
                }
            }
        }

        guard let scheduleId = scheduleId else {
            fatalError("Schedule wasn't created?")
        }

        print(
            try await ScheduleInfoQuery()
                .scheduleId(scheduleId)
                .execute(client)
        )

        let thresholdDeleteTx = AccountDeleteTransaction()

        try thresholdDeleteTx
            .accountId(thresholdAccount)
            .transferAccountId(env.operatorAccountId)
            .freezeWith(client)

        for (key, account) in zip(privateKeys, accounts) {
            thresholdDeleteTx.sign(key)

            _ = try await AccountDeleteTransaction()
                .accountId(account)
                .transferAccountId(env.operatorAccountId)
                .freezeWith(client)
                .sign(key)
                .execute(client)
                .getReceipt(client)
        }

        _ =
            try await thresholdDeleteTx
            .execute(client)
            .getReceipt(client)
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
