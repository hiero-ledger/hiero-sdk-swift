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

        print("Long Term Scheduled Transaction Example Start!")

        /*
        * Step 0: Create and configure the client
        */
        let client = try Client.forName(env.networkName)
        // All generated transactions will be paid by this account and signed by this key.
        client.setOperator(env.operatorAccountId, env.operatorKey)

        /*
        * Step 1: Create key pairs
        */
        let privateKey1 = PrivateKey.generateEd25519()
        let privateKey2 = PrivateKey.generateEd25519()

        print("Creating Key List... (w/ threshold, 2 of 2 keys generated above is required to modify the account)")
        let thresholdKey = KeyList(
            keys: [.single(privateKey1.publicKey), .single(privateKey2.publicKey)], threshold: 2)
        print("Created key list: \(thresholdKey)")

        /*
        * Step 2: Create the account
        */
        print("Creating new account... (w/ above key list as an account key).")
        let aliceId = try await AccountCreateTransaction()
            .keyWithoutAlias(.keyList(thresholdKey))
            .initialBalance(Hbar(2))
            .execute(client)
            .getReceipt(client)
            .accountId!

        print("Created new account with ID: \(aliceId)")

        /*
        * Step 3:
        * Schedule a transfer transaction of 1 hbar from the newly created account to the operator account.
        * The transaction will be scheduled with expirationTime = 24 hours from now and waitForExpiry = false.
        */
        print("Creating new scheduled transaction with 1 day expiry...")
        var transfer = TransferTransaction()
            .hbarTransfer(aliceId, -1)
            .hbarTransfer(env.operatorAccountId, 1)

        let scheduleId = try await transfer.schedule().isWaitForExpiry(false)
            .expirationTime(.now + .seconds(86400))
            .execute(client)
            .getReceipt(client)
            .scheduleId!

        /*
         * Step 4: Sign the transaction with one key and verify the transaction is not executed
         */
        print("Signing the transaction with one key...")
        _ = try await ScheduleSignTransaction()
            .scheduleId(scheduleId)
            .freezeWith(client)
            .sign(privateKey1)
            .execute(client)
            .getReceipt(client)

        var info = try await ScheduleInfoQuery(scheduleId: scheduleId).execute(client)

        print("Scheduled transaction is not executed yet. Executed at: \(info.executedAt?.description ?? "nil")")

        /*
        * Step 5: Sign the transaction with the second key and verify the transaction is executed
        */
        var accountBalance = try await AccountInfoQuery(accountId: aliceId).execute(client)
        print("Alice's balance before scheduled transaction: \(accountBalance.balance)")

        print("Signing the transaction with the second key...")
        _ = try await ScheduleSignTransaction()
            .scheduleId(scheduleId)
            .freezeWith(client)
            .sign(privateKey2)
            .execute(client)
            .getReceipt(client)

        accountBalance = try await AccountInfoQuery(accountId: aliceId).execute(client)

        print("Alice's balance after scheduled transaction: \(accountBalance.balance)")

        info = try await ScheduleInfoQuery(scheduleId: scheduleId).execute(client)

        print("Scheduled transaction is executed. Executed at: \(info.executedAt?.description ?? "nil")")

        /*
         * Step 6:
         * Schedule another transfer transaction of 1 Hbar from the account to the operator account
         * with an expirationTime of 10 seconds in the future and waitForExpiry=true.
        */
        print("Creating new scheduled transaction with 10 seconds expiry...")
        transfer = TransferTransaction()
            .hbarTransfer(aliceId, -1)
            .hbarTransfer(env.operatorAccountId, 1)

        let scheduleId2 = try await transfer.schedule().isWaitForExpiry(true).expirationTime(.now + .seconds(10))
            .execute(client).getReceipt(client).scheduleId!

        let startTime = Timestamp.now
        var elapsedTime: UInt64 = 0

        /*
        * Step 7:
        * Sign the transaction with one key and verify the transaction is not executed
        */
        print("Signing the new scheduled transaction with one key...")
        _ = try await ScheduleSignTransaction()
            .scheduleId(scheduleId2)
            .freezeWith(client)
            .sign(privateKey1)
            .execute(client)
            .getReceipt(client)

        info = try await ScheduleInfoQuery(scheduleId: scheduleId2).execute(client)

        print("Scheduled transaction is not executed yet. Executed at: \(info.executedAt?.description ?? "nil")")

        /*
         * Step 8:
         * Update the account's key to be only the one key
         * that has already signed the scheduled transfer.
         */
        print("Updating the account's key to be only the one key that has already signed the scheduled transfer...")
        _ = try await AccountUpdateTransaction()
            .accountId(aliceId)
            .key(.single(privateKey1.publicKey))
            .freezeWith(client)
            .sign(privateKey1)
            .sign(privateKey2)
            .execute(client)
            .getReceipt(client)

        /*
        * Step 9:
        * Verify that the transfer successfully executes roughly at the time of its expiration.
        */
        accountBalance = try await AccountInfoQuery(accountId: aliceId).execute(client)

        print("Alice's account balance before schedule transfer: \(accountBalance.balance)")

        while elapsedTime < 10 * 1000 {
            elapsedTime = Timestamp.now.unixTimestampNanos - startTime.unixTimestampNanos
            print("Elsapsed time: \(elapsedTime / 1_000_000_000)")
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }

        accountBalance = try await AccountInfoQuery(accountId: aliceId).execute(client)
        print("Alice's account balance after schedule transfer: \(accountBalance.balance)")

        print("Successfully executed scheduled transaction")
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
