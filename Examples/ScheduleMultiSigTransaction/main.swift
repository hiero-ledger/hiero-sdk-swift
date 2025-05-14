// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero
import HieroExampleUtilities

@main
internal enum Program {
    internal static func main() async throws {
        let env = try Environment.load()
        let client = try Client.forName(env.networkName)

        // Defaults the operator account ID and key such that all generated transactions will be paid for
        // by this account and be signed by this key
        client.setOperator(env.operatorAccountId, env.operatorKey)

        // Generate 3 random keys
        let key1 = PrivateKey.generateEd25519()
        let key2 = PrivateKey.generateEd25519()
        let key3 = PrivateKey.generateEd25519()

        // Create a keylist from those keys. This key will be used as the new account's key
        // The reason we want to use a `KeyList` is to simulate a multi-party system where
        // multiple keys are required to sign.
        let keyList: KeyList = [.single(key1.publicKey), .single(key2.publicKey), .single(key3.publicKey)]

        print("key1 private = \(key1)")
        print("key1 public = \(key1.publicKey)")
        print("key1 private = \(key2)")
        print("key2 public = \(key2.publicKey)")
        print("key1 private = \(key3)")
        print("key3 public = \(key3.publicKey)")
        print("key_list = \(keyList)")

        // Creat the account with the `KeyList`
        // The only _required_ property here is `key`
        let response = try await AccountCreateTransaction()
            .nodeAccountIds([3])
            .keyWithoutAlias(.keyList(keyList))
            .initialBalance(Hbar(10))
            .execute(client)

        // This will wait for the receipt to become available
        let createReceipt = try await response.getReceipt(client)

        let accountId = createReceipt.accountId!

        print("accountId = \(accountId)")

        // Create a transfer transaction with 2/3 signatures.
        let transferTransaction = TransferTransaction()
            .hbarTransfer(accountId, -Hbar(1))
            .hbarTransfer(env.operatorAccountId, Hbar(1))

        // Schedule the transaction
        let scheduleReceipt =
            try await transferTransaction
            .schedule()
            .payerAccountId(env.operatorAccountId)
            .adminKey(.single(env.operatorKey.publicKey))
            .freezeWith(client)
            .sign(key2)
            .execute(client)
            .getReceipt(client)

        // Get the schedule ID from the receipt
        let scheduleId = scheduleReceipt.scheduleId!

        print("scheduleId = \(scheduleId)")

        // Get the schedule info to see if `signatories` is populated with 2/3 signatures
        let info = try await ScheduleInfoQuery()
            .nodeAccountIds([response.nodeAccountId])
            .scheduleId(scheduleId)
            .execute(client)

        print("Schedule Info = \(info)")

        let scheduledTransfer = try info.scheduledTransaction
        guard let transferTransaction = scheduledTransfer as? TransferTransaction else {
            fatalError("Expected TransferTransaction")
        }

        let transfers = transferTransaction.hbarTransfers

        // Make sure the transfer transaction is what we expect
        precondition(transfers.count == 2, "more transfers than expected")

        precondition(transfers[accountId] == -Hbar(1))
        precondition(transfers[env.operatorAccountId] == Hbar(1))

        print("sending schedule sign transaction")

        // Finally send this last signature to Hiero. This last signature _should_ mean the transaction executes
        // since all 3 signatures have been provided.
        _ = try await ScheduleSignTransaction()
            .nodeAccountIds([response.nodeAccountId])
            .scheduleId(scheduleId)
            .freezeWith(client)
            .sign(key3)
            .execute(client)
            .getReceipt(client)

        // Query the schedule info again
        _ = try await ScheduleInfoQuery()
            .nodeAccountIds([response.nodeAccountId])
            .scheduleId(scheduleId)
            .execute(client)
    }
}
