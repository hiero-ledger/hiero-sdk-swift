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

        // Generate four new Ed25519 private, public key pairs.

        let privateKeys = (0..<4).map { _ in PrivateKey.generateEd25519() }

        for (index, key) in privateKeys.enumerated() {
            print("public key \(index + 1): \(key.publicKey)")
            print("private key \(index + 1), \(key)")
        }

        // require 3 of the 4 keys we generated to sign on anything modifying this account
        let transactionKey = KeyList(
            keys: privateKeys.map { .single($0.publicKey) },
            threshold: 3
        )

        let receipt = try await AccountCreateTransaction()
            .keyWithoutAlias(.keyList(transactionKey))
            .initialBalance(.fromTinybars(1))
            .accountMemo("3-of-4 multi-sig account")
            .execute(client)
            .getReceipt(client)

        let multiSigAccountId = receipt.accountId!

        print("3-of-4 multi-sig account ID: \(multiSigAccountId)")

        let balance = try await AccountBalanceQuery()
            .accountId(multiSigAccountId)
            .execute(client)

        print("Balance of account \(multiSigAccountId): \(balance.hbars).")

        // schedule crypto transfer from multi-sig account to operator account
        let transferTransaction = TransferTransaction()
            .hbarTransfer(multiSigAccountId, .fromTinybars(-1))
            .hbarTransfer(env.operatorAccountId, .fromTinybars(1))

        let txScheduleReceipt =
            try await transferTransaction
            .schedule()
            .freezeWith(client)
            .sign(privateKeys[0])
            .execute(client)
            .getReceipt(client)

        print("Schedule status: \(txScheduleReceipt.status)")
        let scheduleId = txScheduleReceipt.scheduleId!
        print("Schedule ID: \(scheduleId)")
        let scheduledTxId = txScheduleReceipt.scheduledTransactionId!
        print("Scheduled tx ID: \(scheduledTxId)")

        // add 2 signature
        let txScheduleSign1Receipt = try await ScheduleSignTransaction()
            .scheduleId(scheduleId)
            .freezeWith(client)
            .sign(privateKeys[1])
            .execute(client)
            .getReceipt(client)

        print("1. ScheduleSignTransaction status: \(txScheduleSign1Receipt.status)")

        // add 3 signature
        let txScheduleSign2Receipt = try await ScheduleSignTransaction()
            .scheduleId(scheduleId)
            .freezeWith(client)
            .sign(privateKeys[2])
            .execute(client)
            .getReceipt(client)

        print("2. ScheduleSignTransaction status: \(txScheduleSign2Receipt.status)")

        // query schedule
        let scheduleInfo = try await ScheduleInfoQuery()
            .scheduleId(scheduleId)
            .execute(client)

        print(scheduleInfo)

        // query triggered scheduled tx
        let recordScheduledTx = try await TransactionRecordQuery()
            .transactionId(scheduledTxId)
            .execute(client)

        print(recordScheduledTx)
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
